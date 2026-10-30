# frozen_string_literal: true

require "concurrent"

# :nocov:
module Primer
  # Test-only barrier for fixture requests. A fixture controller action calls
  # `pass(token)`, which blocks the server thread until the test releases that
  # attempt. Each token records every attempt in order, so a test can wait for
  # attempt n to start, release it with a status and count the attempts.
  module RequestGate
    PASS_TIMEOUT = 10
    WAIT_TIMEOUT = 5

    Record = Struct.new(:mutex, :condition, :attempts)
    Attempt = Struct.new(:started, :released, :status)

    @registry = Concurrent::Map.new
    @draining = Concurrent::AtomicBoolean.new(false)

    module_function

    # Called by the server. Returns the status the test released the attempt with.
    def pass(token)
      return 200 if @draining.true?

      attempt = Attempt.new(Concurrent::Event.new, Concurrent::Event.new, 200)
      record = record_for(token)
      registered = record.mutex.synchronize do
        # release_all! may have started draining since the check above; it
        # releases attempts under this mutex, so a later one would block
        next false if @draining.true?

        record.attempts << attempt
        record.condition.broadcast
        true
      end
      return 200 unless registered

      attempt.started.set

      raise "RequestGate: #{token} attempt was not released within #{PASS_TIMEOUT}s" unless attempt.released.wait(PASS_TIMEOUT)

      attempt.status
    end

    def wait_until_started(token, attempt: 1, timeout: WAIT_TIMEOUT)
      found = attempt_for(token, attempt, timeout)
      raise "RequestGate: #{token} attempt #{attempt} did not start within #{timeout}s" unless found.started.wait(timeout)
    end

    def release(token, attempt: 1, status: 200)
      found = attempt_for(token, attempt, WAIT_TIMEOUT)
      found.status = status
      found.released.set
    end

    def count(token)
      record = record_for(token)
      record.mutex.synchronize { record.attempts.size }
    end

    # Releases every pending attempt and lets later requests through until
    # `reset!`, so no server thread stays blocked after a test.
    def release_all!
      @draining.make_true
      @registry.each_value do |record|
        record.mutex.synchronize { record.attempts.each { |a| a.released.set } }
      end
    end

    def reset!
      @registry.clear
      @draining.make_false
    end

    def record_for(token)
      @registry.compute_if_absent(token.to_s) { Record.new(Mutex.new, ConditionVariable.new, []) }
    end

    def attempt_for(token, attempt, timeout)
      record = record_for(token)
      deadline = Concurrent.monotonic_time + timeout

      record.mutex.synchronize do
        while record.attempts.size < attempt
          remaining = deadline - Concurrent.monotonic_time
          raise "RequestGate: #{token} attempt #{attempt} did not arrive within #{timeout}s" if remaining <= 0

          record.condition.wait(record.mutex, remaining)
        end

        record.attempts[attempt - 1]
      end
    end
  end
end
