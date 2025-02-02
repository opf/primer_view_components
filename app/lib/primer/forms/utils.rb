# frozen_string_literal: true

module Primer
  # :nodoc:
  module Forms
    # :nodoc:
    module Utils
      include Primer::ClassNameHelper

      PRIMER_UTILITY_KEYS = Primer::Classify::Utilities::UTILITIES.keys.freeze

      # Unfortunately this bug (https://github.com/ruby/ruby/pull/5646) prevents us from using
      # Ruby's native Module.const_source_location. Instead we have to fudge it by searching
      # for the file in the configured autoload paths. Doing so relies on Rails' autoloading
      # conventions, so it should work ok. Zeitwerk also has this information but lacks a
      # public API to map constants to source files.
      #
      # Now that the Ruby bug above has been fixed and released, this method should be used only
      # as a fallback for older Rubies.
      def const_source_location(class_name)
        return nil unless class_name

        if (location = Object.const_source_location(class_name)&.[](0))
          return location
        end

        # NOTE: underscore respects namespacing, i.e. will convert Foo::Bar to foo/bar.
        class_path = "#{class_name.underscore}.rb"

        # Prefer Zeitwerk-managed paths, falling back to ActiveSupport::Dependencies if Zeitwerk
        # is disabled or not in use (i.e. the case for older Rails versions).
        autoload_paths = if Rails.respond_to?(:autoloaders) && Rails.autoloaders.zeitwerk_enabled?
          Rails.autoloaders.main.dirs
        else
          ActiveSupport::Dependencies.autoload_paths
        end

        autoload_paths.each do |autoload_path|
          absolute_path = File.join(autoload_path, class_path)
          return absolute_path if File.exist?(absolute_path)
        end

        nil
      end

      # This method does the following:
      #
      # 1. Runs Primer's classify routine to convert entries like mb: 1 to mb-1.
      # 2. Runs classify on both options[:class] and options[:classes]. The first
      #    is expected by Rails/HTML while the second is specific to Primer.
      # 3. Combines options[:class] and options[:classes] into options[:class]
      #    so the options hash can be easily passed to Rails form builder methods.
      #
      def classify(options)
        options[:classes] = class_names(options.delete(:class), options[:classes])
        options.merge!(Primer::Classify.call(options))
        options.except!(*PRIMER_UTILITY_KEYS)
        options[:class] = class_names(options[:class], options.delete(:classes))
        options
      end
    end

    Utils.extend(Utils)
  end
end
