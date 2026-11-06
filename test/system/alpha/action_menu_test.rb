# frozen_string_literal: true

require "system/test_case"

module Alpha
  class IntegrationActionMenuTest < System::TestCase
    include Primer::ClipboardTestHelpers
    include Primer::JsTestHelpers
    include Primer::KeyboardTestHelpers

    def self.errors_to_retry
      # The logic in primer/behaviors' focus-zone code can cause weird race conditions
      # that mess with `document.activeElement`, making it slightly unreliable in the
      # test environment.
      @errors_to_retry ||= [Minitest::Assertion].tap do |error_classes|
        if Primer::DriverTestHelpers.firefox?
          error_classes << Selenium::WebDriver::Error::UnexpectedAlertOpenError
        end
      end
    end

    ###### HELPER METHODS ######

    def click_on_invoker_button(expect_to_open: true)
      attempts = 0
      max_attempts = 3

      begin
        attempts += 1

        find("action-menu button[aria-controls]").click

        if expect_to_open
          assert_selector "anchored-position:popover-open"
        end

        STDERR.puts "Succeeded" if attempts > 1
      rescue Minitest::Assertion => e
        raise e if attempts >= max_attempts
        STDERR.puts "Menu failed to open, retrying (attempt #{attempts} of #{max_attempts})"
        retry
      end
    end

    def click_on_item(idx, level: 1)
      items = find_all("action-menu ul[data-level='#{level}'] > li")
      items[idx - 1].click
    end

    def click_on_item_by_id(id)
      find("li[data-item-id='#{id}']").click
    end

    def click_on_first_item(**kwargs)
      click_on_item(1, **kwargs)
    end

    def click_on_second_item(**kwargs)
      click_on_item(2, **kwargs)
    end

    def click_on_third_item(**kwargs)
      click_on_item(3, **kwargs)
    end

    def click_on_fourth_item(**kwargs)
      click_on_item(4, **kwargs)
    end

    def retry_block(max_attempts: 3)
      attempts = 1

      begin
        yield
      rescue Minitest::Assertion => e
        raise e if attempts >= max_attempts
        attempts += 1
        retry
      end
    end

    def open_menu_via_keyboard
      retry_block do
        focus_on_invoker_button

        # open menu, "click" on first item
        activate_via_enter
        assert_selector "anchored-position:popover-open" # wait for menu to open

        # make sure the first list item is the active element
        assert_selector "[role=menuitem], [role=menuitemradio], [role=menuitemcheckbox]" do |button|
          page.evaluate_script("document.activeElement === arguments[0]", button)
        end
      end
    end

    def sub_menu_item
      find("action-menu [role=menuitem][popovertarget]", visible: :all)
    end

    def sub_menu_id
      sub_menu_item["popovertarget"]
    end

    def wait_for_animation_frames(count = 2)
      page.evaluate_async_script(<<~JS, count)
        const [remaining, done] = arguments
        const step = (n) => n === 0 ? done() : requestAnimationFrame(() => step(n - 1))
        step(remaining)
      JS
    end

    def assert_sub_menu_closed_and_parent_open
      assert_no_selector("##{sub_menu_id}:popover-open", visible: :all)
      assert_selector("action-menu [role=menuitem][popovertarget]", focused: true)
      assert_primary_menu_stays_open
    end

    def assert_primary_menu_stays_open
      # The focusout handler closes the menu one frame late, so make sure the primary
      # menu is still open after it has had the chance to run.
      wait_for_animation_frames
      assert_selector("action-menu > anchored-position:popover-open")
    end

    def close_dialog
      find("[data-close-dialog-id][aria-label=Close]").click
    end

    def focus_on_invoker_button
      page.evaluate_script(<<~JS)
        document.querySelector('action-menu button[aria-controls]').focus()
      JS
    end

    def wait_until(timeout: Capybara.default_max_wait_time, message: "Timed out waiting for condition")
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout

      until yield
        raise Minitest::Assertion, message if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline

        sleep 0.05
      end
    end

    def set_menu_src(**params)
      page.execute_script(<<~JS, params.to_json)
        const menu = document.querySelector('action-menu')
        const base = menu.getAttribute('src').split('?')[0]
        const q = new URLSearchParams(JSON.parse(arguments[0])).toString()
        menu.setAttribute('src', q ? `${base}?${q}` : base)
      JS
    end

    # Marks the current primary fragment so a test can wait for its completion
    # in the browser even after it has been superseded and detached.
    def watch_current_fragment(name)
      page.execute_script(<<~JS, name)
        const name = arguments[0]
        const f = document.querySelector('action-menu anchored-position .Overlay-body > include-fragment')
        window.__done ||= {}
        for (const t of ['include-fragment-replaced', 'error']) f.addEventListener(t, () => { window.__done[name] = true })
      JS
    end

    def wait_for_fragment_done(name)
      wait_until { page.evaluate_script("!!(window.__done || {})[#{name.to_json}]") }
    end

    def menu_src
      find("action-menu", visible: :all)[:src]
    end

    PRIMARY_FRAGMENT = "action-menu anchored-position .Overlay-body > include-fragment"

    def primary_fragment_js
      "document.querySelector(#{PRIMARY_FRAGMENT.to_json})"
    end

    # Keeps the loading spinner markup so tests can build their own fragments.
    def stash_spinner_markup
      page.execute_script("window.__spinner = document.querySelector('action-menu').loaderTemplate.content.firstElementChild.innerHTML")
    end

    def close_menu
      page.execute_script("document.querySelector('action-menu').overlay.hidePopover()")
      refute_selector "anchored-position:popover-open"
    end

    # Opens the menu, waits for its deferred items and closes it again.
    def load_and_close_menu
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_selector "action-menu .ActionListItem-label", exact_text: "Copy link"
      close_menu
    end

    # Opens the menu and waits for its deferred items, leaving it open.
    def load_and_open_menu
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_selector "action-menu .ActionListItem-label", exact_text: "Copy link"
    end

    # Lets the menu's focusout handler, which runs in an animation frame, settle.
    def wait_for_frames
      page.evaluate_async_script("const done = arguments[0]; requestAnimationFrame(() => requestAnimationFrame(done))")
    end

    def assert_spinner_focused
      assert_selector "action-menu include-fragment :focus"
    end

    # Starting from a loaded, open menu: holds request A, then supersedes it
    # with held request B, watching A's fragment for its completion.
    def start_out_of_order_requests
      load_and_open_menu

      set_menu_src(label: "A", gate: "a")
      Primer::RequestGate.wait_until_started("a")
      watch_current_fragment("A")

      set_menu_src(label: "B", gate: "b")
      Primer::RequestGate.wait_until_started("b")
    end

    def assert_item(label)
      assert_selector "action-menu .ActionListItem-label", exact_text: label
    end

    def assert_spinner_visible
      assert_selector "action-menu anchored-position .Overlay-body > include-fragment [role=menuitem]"
    end

    def assert_focused_text(text)
      assert_selector ":focus", exact_text: text
    end

    def open_sub_menu(label)
      find("action-menu .ActionListItem-label", exact_text: label).click
    end

    # Opens a sub-menu whose request is held by `gate` and releases it once
    # the sub-menu's spinner has focus, the order a slow response arrives in.
    def open_held_sub_menu(label, gate, attempt: 1)
      open_sub_menu label
      Primer::RequestGate.wait_until_started(gate, attempt: attempt)
      assert_spinner_focused
      Primer::RequestGate.release(gate, attempt: attempt)
    end

    # The sub-menu opened by the item labelled `label`
    def sub_menu_js(label)
      <<~JS.squish
        (() => {
          const label = [...document.querySelectorAll('action-menu .ActionListItem-label')].find(l => l.textContent.trim() === #{label.to_json});
          const id = label?.closest('[popovertarget]')?.getAttribute('popovertarget');
          return id ? document.getElementById(id) : null
        })()
      JS
    end

    # Focus is on the sub-menu's own loaded item `item`, not on its spinner
    # or an item of a sub-menu nested in it
    def assert_focus_in_sub_menu(label, item: "Copy link")
      wait_until(message: "Focus not on #{item.inspect} in sub-menu #{label.inspect}") do
        page.evaluate_script(<<~JS.squish)
          (() => {
            const subMenu = #{sub_menu_js(label)};
            const active = document.activeElement;
            return !!subMenu && active.closest('anchored-position') === subMenu &&
              !!active.closest('[role^=menuitem]') && !active.closest('include-fragment') &&
              active.textContent.trim() === #{item.to_json}
          })()
        JS
      end
    end

    def sub_menu_open?(label)
      page.evaluate_script("!!#{sub_menu_js(label)}?.matches(':popover-open')")
    end

    def primary_menu_open?
      page.evaluate_script("document.querySelector('action-menu').overlay.matches(':popover-open')")
    end

    # Puts a fragment for `query` into the primary body, replacing its
    # children unless `append` or `prepend` is given. A nil `query` keeps the
    # host's current src unchanged.
    def insert_external_fragment(query, loading: "eager", append: false, prepend: false, menu_js: "document.querySelector('action-menu')")
      mode = "replaceChildren"
      mode = "prepend" if prepend
      mode = "append" if append

      page.execute_script(<<~JS, query, loading, mode)
        const [query, loading, mode] = arguments
        const menu = #{menu_js}
        const body = menu.overlay.querySelector('.Overlay-body')
        const src = menu.getAttribute('src')
        const fragment = document.createElement('include-fragment')
        fragment.setAttribute('src', query === null ? src : `${src.split('?')[0]}?${query}`)
        fragment.setAttribute('loading', loading)
        fragment.innerHTML = window.__spinner
        body[mode](fragment)
      JS
    end

    # Inserts a fragment the way Idiomorph inserts content with ids: connected
    # first, attributes and children afterwards.
    def shell_first_fragment(query)
      page.execute_script(<<~JS, query)
        const menu = document.querySelector('action-menu')
        const body = menu.overlayBody
        const f = document.createElement('include-fragment')
        body.append(f)                       // connects with no attributes, like Idiomorph
        f.setAttribute('loading', 'lazy')
        f.setAttribute('src', `${menu.getAttribute('src').split('?')[0]}?${arguments[0]}`)
        f.innerHTML = window.__spinner
      JS
    end

    # Removes the menu from the document, keeping it in window.__m.
    def detach_menu
      page.execute_script(<<~JS)
        const m = document.querySelector('action-menu')
        window.__p = m.parentNode
        m.remove()
        window.__m = m
      JS
    end

    def reattach_menu
      page.execute_script("window.__p.append(window.__m)")
    end

    # Empties the primary body the way a morph of the server markup does
    def empty_primary_body
      page.execute_script("document.querySelector('action-menu').overlayBody.replaceChildren()")
    end

    # Starts held request "e", detaches the menu and fails the request while
    # the menu is detached, leaving it detached.
    def fail_request_while_detached
      set_menu_src(gate: "e")
      Primer::RequestGate.wait_until_started("e")
      watch_current_fragment("e1")
      detach_menu

      Primer::RequestGate.release("e", status: 500)
      wait_for_fragment_done("e1")
      wait_until do
        page.evaluate_script(
          "!!window.__m.querySelector('anchored-position .Overlay-body > include-fragment.is-error')"
        )
      end
    end

    # Starting from a loaded, closed menu: opens it on held request "e" and
    # fails that request, leaving the menu open with the failed loader.
    def fail_request_while_open
      load_and_close_menu
      set_menu_src(gate: "e")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("e")
      Primer::RequestGate.release("e", status: 500)
      assert_selector "action-menu include-fragment.is-error", visible: :all
    end

    def detached_menu_includes?(text)
      page.evaluate_script("window.__m.textContent.includes(#{text.to_json})")
    end

    def detached_menu_has_label?(text)
      page.evaluate_script(<<~JS, text)
        Array.from(window.__m.querySelectorAll('.ActionListItem-label')).some(l => l.textContent.trim() === arguments[0])
      JS
    end

    def collect_js_errors
      page.execute_script(<<~JS)
        window.__errors = []
        window.addEventListener('error', (event) => window.__errors.push(String(event.message)))
        window.addEventListener('unhandledrejection', (event) => window.__errors.push(String(event.reason)))
      JS
    end

    def assert_no_alert(message = nil, &block)
      accept_alert(&block)
      assert false, message || "Unexpected alert dialog"
    rescue Capybara::ModalNotFound
      # expected behavior
    end

    def activate_via_enter(**kwargs)
      activate_via(:enter, **kwargs)
    end

    def activate_via_space(**kwargs)
      activate_via(:space, **kwargs)
    end

    def activate_via(*keys, expect_focus_change: true)
      current_item = page.evaluate_script("document.activeElement")
      sub_menu_id = current_item["popovertarget"]
      disabled = current_item["aria-disabled"]

      keyboard.type(*keys)

      return if !expect_focus_change || disabled
      return unless sub_menu_id

      # make sure the first list item in the sub-menu is the active element
      assert_selector("##{sub_menu_id} ul > li [role=menuitem], [role=menuitemradio], [role=menuitemcheckbox]") do |element|
        page.evaluate_script("document.activeElement === arguments[0]", element)
      end
    end

    def arrow_down_to(label)
      counter = 0

      loop do
        break if page.evaluate_script("document.activeElement?.querySelector('.ActionListItem-label')?.textContent?.trim()") == label
        keyboard.type(:down)
        sleep 0.1

        counter += 1

        raise Minitest::Assertion, "Too many down arrows" if counter > 10
      end
    end

    ########## TESTS ############

    def test_dynamic_labels_for_single_select_variant
      visit_preview(:single_select_with_internal_label)
      assert_selector("action-menu button[aria-controls]", text: "Menu: Quote reply")

      click_on_invoker_button
      click_on_first_item

      assert_selector("action-menu button[aria-controls]", text: "Menu: Copy link")

      click_on_invoker_button
      click_on_first_item

      assert_selector("action-menu button[aria-controls]", text: "Menu")
    end

    def test_dynamic_labels_for_multiple_select_variant
      visit_preview(:multiple_select_form, route_format: :json)
      assert_selector("action-menu button[aria-controls]", text: "Strategy: Ours")

      click_on_invoker_button
      click_on_first_item
      click_on_second_item

      assert_selector("action-menu button[aria-controls]", text: "Strategy: Fast forward, Recursive, Ours")

      click_on_invoker_button
      click_on_first_item

      assert_selector("action-menu button[aria-controls]", text: "Strategy: Recursive, Ours")
    end

    def test_anchor_align
      visit_preview(:align_end)

      click_on_invoker_button

      assert_selector("anchored-position[align=end]")
    end

    def test_action_js_onclick
      visit_preview(:with_actions)

      click_on_invoker_button

      accept_alert do
        click_on_first_item
      end
    end

    def test_sub_menu_action_js_onclick
      visit_preview(:with_actions, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item # expand sub-menu

      accept_alert do
        click_on_first_item(level: 2)
      end
    end

    def test_action_js_keydown
      visit_preview(:with_actions)

      open_menu_via_keyboard

      accept_alert do
        # "click" on first item
        activate_via_enter(expect_focus_change: false)
      end
    end

    def test_sub_menu_arrow_left_closes_only_the_sub_menu
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu
      assert_selector("##{sub_menu_id}:popover-open")

      keyboard.type(:left)

      assert_sub_menu_closed_and_parent_open
    end

    def test_sub_menu_escape_closes_only_the_sub_menu
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu
      assert_selector("##{sub_menu_id}:popover-open")

      keyboard.type(:escape)

      assert_sub_menu_closed_and_parent_open
    end

    def test_arrow_left_on_top_level_item_keeps_the_menu_open
      visit_preview(:with_actions)

      open_menu_via_keyboard

      keyboard.type(:left)

      assert_primary_menu_stays_open
    end

    def test_arrow_left_on_top_level_deferred_item_keeps_the_menu_open
      visit_preview(:with_deferred_content)

      open_menu_via_keyboard
      assert_selector "action-menu ul li", text: "Copy link"

      keyboard.type(:left)

      assert_primary_menu_stays_open
    end

    def test_escape_on_primary_menu_returns_focus_to_invoker
      visit_preview(:with_actions)

      open_menu_via_keyboard

      keyboard.type(:escape)

      assert_no_selector "action-menu > anchored-position:popover-open"
      assert_selector "action-menu button[aria-controls]", focused: true
    end

    def test_escape_from_sub_menu_then_primary_menu_returns_focus_to_invoker
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu
      assert_selector("##{sub_menu_id}:popover-open")

      keyboard.type(:escape)
      assert_sub_menu_closed_and_parent_open

      keyboard.type(:escape)

      assert_no_selector "anchored-position:popover-open", visible: :all
      assert_selector "action-menu button[aria-controls]", focused: true
    end

    def test_sub_menu_action_js_keydown
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu

      accept_alert do
        # "click" on first item
        activate_via_enter(expect_focus_change: false)
      end
    end

    def test_action_js_keydown_space
      visit_preview(:with_actions)

      open_menu_via_keyboard

      accept_alert do
        # "click" on first item
        activate_via_space(expect_focus_change: false)
      end
    end

    def test_sub_menu_action_js_keydown_space
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_space # expand sub-menu

      accept_alert do
        # "click" on first item
        activate_via_space(expect_focus_change: false)
      end
    end

    def test_action_js_disabled
      visit_preview(:with_actions, disable_items: true)

      click_on_invoker_button

      assert_no_alert do
        click_on_first_item
      end
    end

    def test_action_js_disabled_keydown
      visit_preview(:with_actions, disable_items: true)

      open_menu_via_keyboard

      assert_no_alert do
        # "click" on first item
        activate_via_enter
      end
    end

    def test_sub_menu_action_js_disabled_keydown
      visit_preview(:with_actions, disable_items: true, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu

      assert_no_alert do
        # "click" on first item
        activate_via_enter
      end
    end

    def test_action_js_disabled_keydown_space
      visit_preview(:with_actions, disable_items: true)

      open_menu_via_keyboard

      assert_no_alert do
        # open menu, "click" on first item
        activate_via_space
      end
    end

    def test_sub_menu_action_js_disabled_keydown_space
      visit_preview(:with_actions, disable_items: true, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_space # expand sub-menu

      assert_no_alert do
        # "click" on first item
        activate_via_space
      end
    end

    def test_action_keydown_on_icon_button
      visit_preview(:with_icon_button)

      open_menu_via_keyboard

      assert_selector "anchored-position"
    end

    def test_action_anchor
      visit_preview(:with_actions)

      click_on_invoker_button
      click_on_second_item

      assert_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_sub_menu_action_anchor
      visit_preview(:with_actions, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item # expand sub-menu
      click_on_second_item(level: 2)

      assert_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_action_anchor_keydown
      visit_preview(:with_actions)

      open_menu_via_keyboard

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_enter(expect_focus_change: false)

      assert_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_sub_menu_action_anchor_keydown
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_enter(expect_focus_change: false) # expand sub-menu

      assert_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_action_anchor_keydown_space
      visit_preview(:with_actions)

      open_menu_via_keyboard

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_space(expect_focus_change: false)

      assert_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_sub_menu_action_anchor_keydown_space
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_space # expand sub-menu

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_space(expect_focus_change: false)

      assert_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_action_anchor_disabled
      visit_preview(:with_actions, disable_items: true)

      click_on_invoker_button
      click_on_second_item

      # assert no navigation took place
      refute_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_sub_menu_action_anchor_disabled
      visit_preview(:with_actions, disable_items: true, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item # expand sub-menu
      click_on_second_item(level: 2)

      # assert no navigation took place
      refute_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_action_anchor_disabled_keydown
      visit_preview(:with_actions, disable_items: true)

      open_menu_via_keyboard

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_enter

      # assert no navigation took place
      refute_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_sub_menu_action_anchor_disabled_keydown
      visit_preview(:with_actions, disable_items: true, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_enter(expect_focus_change: false)

      # assert no navigation took place
      refute_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_action_anchor_disabled_keydown_space
      visit_preview(:with_actions, disable_items: true)

      open_menu_via_keyboard

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_space

      # assert no navigation took place
      refute_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_sub_menu_action_anchor_disabled_keydown_space
      visit_preview(:with_actions, disable_items: true, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_space # expand sub-menu

      # arrow down to second item, "click" second item
      arrow_down_to("Navigate")
      activate_via_space

      # assert no navigation took place
      refute_selector ".action-menu-landing-page", text: "Hello world!"
    end

    def test_action_clipboard_copy
      visit_preview(:with_actions)

      click_on_invoker_button

      clipboard_text = capture_clipboard do
        click_on_third_item
      end

      assert_equal clipboard_text, "Text to copy"
    end

    def test_sub_menu_action_clipboard_copy
      visit_preview(:with_actions, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item # expand sub-menu

      clipboard_text = capture_clipboard do
        click_on_third_item(level: 2)
      end

      assert_equal clipboard_text, "Text to copy"
    end

    def test_action_clipboard_copy_keydown
      visit_preview(:with_actions)

      open_menu_via_keyboard

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_enter
      end

      assert_equal clipboard_text, "Text to copy"
    end

    def test_sub_menu_action_clipboard_copy_keydown
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter # expand sub-menu

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_enter
      end

      assert_equal clipboard_text, "Text to copy"
    end

    def test_action_clipboard_copy_keydown_space
      visit_preview(:with_actions)

      open_menu_via_keyboard

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_space
      end

      assert_equal clipboard_text, "Text to copy"
    end

    def test_sub_menu_action_clipboard_copy_keydown_space
      visit_preview(:with_actions, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_space

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_space
      end

      assert_equal clipboard_text, "Text to copy"
    end

    def test_action_clipboard_copy_disabled
      visit_preview(:with_actions, disable_items: true)

      click_on_invoker_button

      clipboard_text = capture_clipboard do
        click_on_third_item
      end

      assert_nil clipboard_text
    end

    def test_sub_menu_action_clipboard_copy_disabled
      visit_preview(:with_actions, disable_items: true, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item

      clipboard_text = capture_clipboard do
        click_on_third_item(level: 2)
      end

      assert_nil clipboard_text
    end

    def test_action_clipboard_copy_disabled_keydown
      visit_preview(:with_actions, disable_items: true)

      open_menu_via_keyboard

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_enter
      end

      assert_nil clipboard_text
    end

    def test_sub_menu_action_clipboard_copy_disabled_keydown
      visit_preview(:with_actions, disable_items: true, nest_in_sub_menu: true)

      open_menu_via_keyboard
      activate_via_enter

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_enter
      end

      assert_nil clipboard_text
    end

    def test_action_clipboard_copy_disabled_keydown_space
      visit_preview(:with_actions, disable_items: true)

      open_menu_via_keyboard

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_space
      end

      assert_nil clipboard_text
    end

    def test_sub_menu_action_clipboard_copy_disabled_keydown_space
      visit_preview(:with_actions, disable_items: true)

      open_menu_via_keyboard
      activate_via_space

      clipboard_text = capture_clipboard do
        # arrow down to third item, "click" third item
        arrow_down_to("Copy text")
        activate_via_space
      end

      assert_nil clipboard_text
    end

    def test_first_item_is_focused_on_invoker_keydown
      visit_preview(:with_actions)

      open_menu_via_keyboard

      assert_equal page.evaluate_script("document.activeElement").text, "Alert"
    end

    def test_first_item_is_focused_on_invoker_click
      visit_preview(:with_actions)

      click_on_invoker_button

      assert_equal page.evaluate_script("document.activeElement").text, "Alert"
    end

    def test_opens_dialog
      visit_preview(:opens_dialog)

      click_on_invoker_button
      click_on_second_item

      assert_selector "dialog[open]"

      # opening the dialog should close the menu
      refute_selector "action-menu ul li"
    end

    def test_open_then_closing_dialog_restores_focus
      visit_preview(:opens_dialog)

      click_on_invoker_button
      click_on_second_item

      assert_selector "dialog[open]"

      close_dialog

      assert_equal page.evaluate_script("document.activeElement").text, "Menu"
    end

    def test_opens_dialog_on_keydown
      visit_preview(:opens_dialog)

      open_menu_via_keyboard

      # arrow down to second item, "click" second item
      arrow_down_to("Show dialog")
      activate_via_enter

      assert_selector "dialog#my-dialog"
    end

    def test_opens_dialog_on_keydown_space
      visit_preview(:opens_dialog)

      open_menu_via_keyboard

      # arrow down to second item, "click" second item
      arrow_down_to("Show dialog")
      activate_via_space

      assert_selector "dialog#my-dialog"
    end

    def test_closes_sub_menus_when_dialog_opened
      visit_preview(:opens_dialog, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item

      click_on_second_item(level: 2)

      assert_selector "dialog#my-dialog"
      click_on "Cancel"

      click_on_invoker_button
      refute_selector "action-menu ul li", text: "Show dialog"
    end

    def test_single_select_form_submission
      visit_preview(:single_select_form, route_format: :json)

      click_on_invoker_button
      click_on_first_item

      find("input[type=submit]").click

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)
      assert_equal "fast_forward", response["value"]
    end

    def test_single_select_form_uses_label_if_no_value_provided
      visit_preview(:single_select_form, route_format: :json)

      click_on_invoker_button
      click_on_fourth_item

      find("input[type=submit]").click

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)
      assert_equal "Resolve", response["value"]
    end

    def test_multiple_select_form_submission
      visit_preview(:multiple_select_form, route_format: :json)

      click_on_invoker_button
      click_on_first_item
      click_on_second_item

      # close the menu to reveal the submit button
      keyboard.type(:escape)

      find("input[type=submit]").click

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)

      # "ours" is pre-selected
      assert_equal %w[fast_forward recursive ours], response["value"]
    end

    def test_multiple_select_form_submission_in_sub_menu
      visit_preview(:multiple_select_form, route_format: :json, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item
      click_on_first_item(level: 2)
      click_on_second_item(level: 2)

      # close the menus to reveal the submit button
      keyboard.type(:escape, :escape)

      find("input[type=submit]").click

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)

      # "ours" is pre-selected
      assert_equal %w[fast_forward recursive ours], response["value"]
    end

    def test_multiple_select_form_uses_label_if_no_value_provided
      visit_preview(:multiple_select_form, route_format: :json)

      click_on_invoker_button
      click_on_first_item
      click_on_fourth_item

      # close the menu to reveal the submit button
      keyboard.type(:escape)

      find("input[type=submit]").click

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)

      # "ours" is pre-selected
      assert_equal %w[fast_forward ours Resolve], response["value"]
    end

    def test_multiple_select_does_set_dynamic_label_for_preselected_item
      visit_preview(:multiple_select_form, route_format: :json)
      assert_selector("action-menu[data-ready='true'] button[aria-controls]", exact_text: "Strategy: Ours")
    end

    def test_individual_items_can_submit_post_requests_via_forms
      visit_preview(:with_actions, route_format: :json)

      click_on_invoker_button
      click_on_fourth_item

      response = JSON.parse(find("pre").text)
      assert_equal "bar", response["value"]
    end

    def test_sub_menu_individual_items_can_submit_post_requests_via_forms
      visit_preview(:with_actions, route_format: :json, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item
      click_on_fourth_item(level: 2)

      response = JSON.parse(find("pre").text)
      assert_equal "bar", response["value"]
    end

    def test_single_select_items_can_submit_forms
      visit_preview(:single_select_form_items, route_format: :json)

      click_on_invoker_button
      click_on_first_item

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)
      assert_equal "group-by-repository", response["value"]
    end

    def test_single_select_items_can_submit_forms_on_enter
      visit_preview(:single_select_form_items, route_format: :json)

      open_menu_via_keyboard

      # "click" first item
      activate_via_enter

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)
      assert_equal "group-by-repository", response["value"]
    end

    def test_single_select_items_can_submit_forms_on_keydown_space
      visit_preview(:single_select_form_items, route_format: :json)

      open_menu_via_keyboard

      # "click" first item
      activate_via_space

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)
      assert_equal "group-by-repository", response["value"]
    end

    def test_single_select_items_can_submit_forms_with_multiple_fields
      visit_preview(:single_select_form_items, route_format: :json)

      click_on_invoker_button
      click_on_first_item

      # for some reason the JSON response is wrapped in HTML, I have no idea why
      response = JSON.parse(find("pre").text)
      assert_equal "query", response.dig("other_params", "query")
    end

    def test_deferred_loading
      visit_preview(:with_deferred_content)

      click_on_invoker_button

      assert_selector "action-menu ul li", text: "Copy link"
      assert_selector "action-menu ul li", text: "Quote reply"
      assert_selector "action-menu ul li", text: "Reference in new issue"

      assert_equal page.evaluate_script("document.activeElement").text, "Copy link"
    end

    def test_deferred_loading_on_keydown
      visit_preview(:with_deferred_content)

      open_menu_via_keyboard

      # wait for menu to load
      assert_selector "action-menu ul li", text: "Copy link"
      assert_equal page.evaluate_script("document.activeElement").text, "Copy link"
    end

    def test_deferred_loading_overlay_positioned_within_viewport
      visit_preview(:with_deferred_content_near_bottom_of_viewport)
      click_on_invoker_button

      # Wait for lazy content to load
      assert_selector "action-menu ul li", text: "Copy link"

      overlay = find("anchored-position").native.node
      assert overlay.in_viewport?, "Overlay should be positioned within the viewport after deferred content loads"
    end

    def test_deferred_dialog_opens
      visit_preview(:with_deferred_content)

      click_on_invoker_button
      # wait for items to load
      assert_selector "action-menu ul li"
      click_on_fourth_item

      assert_selector "dialog[open]"

      # menu should close
      refute_selector "action-menu ul li"
    end

    def test_refresh_form_backed_menu_repeatedly
      visit_preview(:deferred_refresh_form)
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu

      (1..3).each do |n|
        page.execute_script("document.querySelector('action-menu').removeAttribute('data-ready')")
        set_menu_src(label: n)
        click_on_invoker_button
        assert_selector "action-menu[data-ready=true]", visible: :all
        assert_selector "action-menu .ActionListItem-label", exact_text: "Ours #{n}"
        close_menu
      end

      assert_selector "action-menu .Overlay-body > action-list", count: 1, visible: :all
      assert_selector "action-menu [data-list-inputs]", count: 1, visible: :all
      assert_selector "action-menu .ActionList-sectionDivider, action-menu h3", text: "Strategy", count: 1, visible: :all
      assert_selector "action-menu button[aria-controls]", text: "Ours 3"

      click_on_invoker_button
      find("action-menu .ActionListItem-label", exact_text: "Recursive 3").click
      close_menu

      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_equal %w[ours recursive], response["value"].sort
    end

    def test_refresh_form_backed_menu_empty_selection
      visit_preview(:deferred_refresh_form)
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu

      page.execute_script("document.querySelector('action-menu').removeAttribute('data-ready')")
      set_menu_src(checked: "")
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu

      label = find("action-menu button[aria-controls]").text
      ["Ours", "Recursive", "Fast forward"].each { |name| refute_includes label, name }

      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_nil response["value"]
    end

    def test_form_submits_previous_selection_until_reload_succeeds
      # The reload has failed, or is still held when the form is submitted
      %w[failed pending].each do |state|
        # Starting state: loaded with "Ours" checked, reload started, closed
        gate = "r_#{state}"
        visit_preview(:deferred_refresh_form)
        click_on_invoker_button
        assert_selector "action-menu[data-ready=true]", visible: :all
        set_menu_src(gate: gate)
        Primer::RequestGate.wait_until_started(gate)
        if state == "failed"
          Primer::RequestGate.release(gate, status: 500)
          assert_selector "action-menu include-fragment.is-error", visible: :all
        end
        close_menu

        find("input[type=submit]").click
        response = JSON.parse(find("pre").text)
        assert_equal ["ours"], response["value"], "reload #{state}"
      end
    end

    def test_form_keeps_previous_selection_until_closed_src_change_is_applied
      # Starting state: loaded, closed (form-backed, server checked "ours")
      visit_preview(:deferred_refresh_form)
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_item "Ours"
      close_menu

      set_menu_src(checked: "recursive", gate: "f")
      assert_selector "action-menu input[data-list-input][value='ours']", visible: :all
      assert_selector "action-menu button .Button-label", text: /ours/i
      assert_equal 0, Primer::RequestGate.count("f")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("f")
      Primer::RequestGate.release("f")
      assert_selector "action-menu input[data-list-input][value='recursive']", visible: :all
      assert_no_selector "action-menu input[data-list-input][value='ours']", visible: :all

      # The reloaded selection submits without any further item activation
      close_menu
      assert_selector "action-menu [data-list-inputs]", count: 1, visible: :all
      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_equal ["recursive"], response["value"]
    end

    def test_form_submits_previous_selection_after_reconnect_while_reload_is_pending
      # Starting state: loaded with "Ours" checked, closed, reload A held,
      # then the menu is moved
      visit_preview(:deferred_refresh_form)
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      set_menu_src(gate: "a")
      Primer::RequestGate.wait_until_started("a")
      close_menu
      detach_menu
      reattach_menu

      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_equal ["ours"], response["value"]
    end

    def test_single_select_form_submits_previous_selection_after_reconnect_and_failed_reload
      # Starting state: loaded with "Ours" checked, reload failed, then the
      # menu is moved
      visit_preview(:deferred_refresh_form, select_variant: :single)
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      set_menu_src(variant: "single", gate: "e")
      Primer::RequestGate.wait_until_started("e")
      Primer::RequestGate.release("e", status: 500)
      assert_selector "action-menu include-fragment.is-error", visible: :all
      close_menu
      detach_menu
      reattach_menu

      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_equal "ours", response["value"]
    end

    def test_form_selection_stays_in_sync_when_focus_starts_a_new_load
      # Starting state: loaded single-select form, closed
      visit_preview(:deferred_refresh_form, select_variant: :single)
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu

      set_menu_src(variant: "single", label: "A", checked: "recursive", gate: "a")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("a")
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.addEventListener('focusin', function onFocusIn(event) {
          if (!event.target.matches('[role="menuitemradio"]')) return
          menu.removeEventListener('focusin', onFocusIn)
          menu.setAttribute('src', `${menu.getAttribute('src').split('?')[0]}?variant=single&label=B&checked=fast_forward&gate=b`)
        })
      JS

      Primer::RequestGate.release("a")
      Primer::RequestGate.wait_until_started("b")
      assert_selector "action-menu button[aria-controls]", text: "Strategy: Recursive A"
      assert_selector "action-menu input[name='foo'][value='recursive']", visible: :all
      assert_no_selector "action-menu input[name='foo'][value='fast_forward']", visible: :all

      Primer::RequestGate.release("b")
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_selector "action-menu button[aria-controls]", text: "Strategy: Fast forward B"
      assert_selector "action-menu input[name='foo'][value='fast_forward']", visible: :all
      assert_no_selector "action-menu input[name='foo'][value='recursive']", visible: :all
      close_menu

      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_equal "fast_forward", response["value"]
    end

    def test_cloned_menu_without_selection_keeps_field_name
      # Starting state: loaded with nothing checked, closed, then cloned
      visit_preview(:deferred_refresh_form)
      set_menu_src(checked: "")
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.replaceWith(menu.cloneNode(true))
      JS

      page.execute_script("const m = document.querySelector('action-menu'); m.checkItem(m.items[0].parentElement)")
      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_equal ["fast_forward"], response["value"]
    end

    def test_cloned_menu_keeps_original_label
      # Starting state: loaded with "Ours" selected, closed
      visit_preview(:deferred_refresh_form)
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu
      assert_includes find("action-menu button[aria-controls]").text, "Ours"

      # A clone (eg. a Turbo snapshot restore) starts from the updated button
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.replaceWith(menu.cloneNode(true))
      JS
      set_menu_src(checked: "")
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu

      label = find("action-menu button[aria-controls]").text
      refute_includes label, "Ours"
    end

    def test_adopted_form_response_uses_new_field_name
      visit_preview(:deferred_refresh_form)
      stash_spinner_markup
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu

      insert_external_fragment("name=bar")
      assert_selector "action-menu[src$='?name=bar']", visible: :all
      assert_selector "action-menu[data-ready=true]", visible: :all

      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_nil response["value"]
      assert_equal ["ours"], response["other_params"]["bar"]
    end

    def test_single_select_deferred_form_with_no_checked_item_submits_no_value
      # Starting state: unloaded single-select form, closed
      visit_preview(:deferred_refresh_form, select_variant: :single)

      set_menu_src(variant: "single", checked: "")
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_selector "action-menu [role=menuitemradio]"
      close_menu

      find("input[type=submit]").click
      response = JSON.parse(find("pre").text)
      assert_nil response["value"]
    end

    def test_first_open_inserts_loader_from_template
      # Starting state: unloaded, closed
      visit_preview(:deferred_refresh)
      assert_no_selector "action-menu anchored-position .Overlay-body > include-fragment", visible: :all

      click_on_invoker_button
      assert_item "Copy link"
      assert_selector "action-menu[data-ready=true]", visible: :all
    end

    def test_refresh_closed_lazy_keeps_content_until_open
      # Starting state: loaded, closed
      visit_preview(:deferred_refresh)
      load_and_close_menu

      set_menu_src(label: "B", gate: "b")
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_selector "action-menu .ActionListItem-label", text: "Copy link", visible: :all
      assert_equal 0, Primer::RequestGate.count("b")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("b")
      assert_spinner_visible

      Primer::RequestGate.release("b")
      assert_item "B"
      assert_equal 1, Primer::RequestGate.count("b")
      assert_selector "action-menu action-list", count: 1
    end

    def test_refresh_before_first_load
      # Starting state: unloaded, closed
      visit_preview(:deferred_refresh)

      set_menu_src(label: "A", gate: "a")
      set_menu_src(label: "B", gate: "b")
      assert_equal 0, Primer::RequestGate.count("b")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("b")
      Primer::RequestGate.release("b")
      assert_item "B"
      assert_selector "action-menu action-list", count: 1
      assert_equal 0, Primer::RequestGate.count("a")
      assert_equal 1, Primer::RequestGate.count("b")
    end

    def test_src_changed_away_and_back_on_closed_menu_keeps_loaded_items
      # Starting state: loaded from gate "a", closed (lazy)
      visit_preview(:deferred_refresh)
      set_menu_src(label: "A", gate: "a")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("a")
      Primer::RequestGate.release("a")
      assert_item "A"
      close_menu

      set_menu_src(label: "B", gate: "b")
      set_menu_src(label: "A", gate: "a")
      assert_selector "action-menu[data-ready=true]", visible: :all
      click_on_invoker_button
      assert_item "A"
      refute_selector "action-menu include-fragment", visible: :all
      assert_equal 1, Primer::RequestGate.count("a")
      assert_equal 0, Primer::RequestGate.count("b")
    end

    def test_relative_then_absolute_src_reloads_once
      # Starting state: loaded, closed
      visit_preview(:deferred_refresh)
      load_and_close_menu

      set_menu_src(label: "R", gate: "r")
      click_on_invoker_button
      Primer::RequestGate.release("r")
      assert_item "R"
      close_menu

      set_absolute_src = <<~JS
        const menu = document.querySelector('action-menu')
        menu.setAttribute('src', new URL(menu.getAttribute('src'), window.location.href).href)
      JS

      page.execute_script(set_absolute_src)
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("r", attempt: 2)
      Primer::RequestGate.release("r", attempt: 2)
      assert_item "R"
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_equal 2, Primer::RequestGate.count("r")
      close_menu

      page.execute_script(set_absolute_src)
      click_on_invoker_button
      assert_item "R"
      refute_selector "action-menu include-fragment", visible: :all
      assert_equal 2, Primer::RequestGate.count("r")
    end

    def test_refresh_ignores_blank_src
      # Starting state: loaded, closed
      visit_preview(:deferred_refresh)
      load_and_close_menu

      page.execute_script("document.querySelector('action-menu').removeAttribute('src')")
      page.execute_script("document.querySelector('action-menu').setAttribute('src', '')")

      click_on_invoker_button
      assert_item "Copy link"
      refute_selector "action-menu include-fragment", visible: :all
    end

    def test_src_set_before_insertion_loads_on_first_open
      # Starting state: unloaded, detached, src changed, reattached
      visit_preview(:deferred_refresh)
      page.execute_script(<<~JS)
        const m = document.querySelector('action-menu')
        const p = m.parentNode; m.remove()
        m.setAttribute('src', m.getAttribute('src').split('?')[0] + '?label=P&gate=p')
        p.append(m)
      JS
      # A load inserts its loader synchronously, before any fetch
      assert_no_selector PRIMARY_FRAGMENT, visible: :all, wait: 0
      assert_equal 0, Primer::RequestGate.count("p")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("p")
      Primer::RequestGate.release("p")
      assert_item "P"
      assert_equal 1, Primer::RequestGate.count("p")
    end

    def test_cloned_loaded_menu_reloads_on_first_open
      # Starting state: loaded, closed; the menu is replaced by a clone of
      # itself (loaded list and template, fresh element: a Turbo snapshot)
      visit_preview(:deferred_refresh)
      set_menu_src(gate: "c")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("c")
      Primer::RequestGate.release("c")
      assert_item "Copy link"
      close_menu
      page.execute_script("const m = document.querySelector('action-menu'); m.replaceWith(m.cloneNode(true))")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("c", attempt: 2)
      assert_spinner_visible
      Primer::RequestGate.release("c", attempt: 2)
      assert_item "Copy link"
    end

    def test_src_set_in_beforetoggle_listener_applies_on_same_open
      # A capturing listener on the document, or on the menu itself added
      # after connect
      %w[document menu].each do |where|
        # Starting state: loaded, closed
        gate = "t_#{where}"
        visit_preview(:deferred_refresh)
        load_and_close_menu

        page.execute_script(<<~JS, where, gate)
          const [where, gate] = arguments
          const menu = document.querySelector('action-menu')
          const target = where === 'document' ? document : menu
          target.addEventListener('beforetoggle', (event) => {
            if (event.newState !== 'open' || event.target !== menu.overlay) return
            menu.setAttribute('src', `${menu.getAttribute('src').split('?')[0]}?label=T&gate=${gate}`)
          }, {capture: true})
        JS

        click_on_invoker_button
        Primer::RequestGate.wait_until_started(gate)
        assert_equal 1, Primer::RequestGate.count(gate)

        Primer::RequestGate.release(gate)
        assert_item "T"
        assert_equal 1, Primer::RequestGate.count(gate)
        assert_focused_text "T"
      end
    end

    def test_refresh_then_open_via_keyboard
      # Starting state: loaded, closed
      visit_preview(:deferred_refresh)
      load_and_close_menu

      set_menu_src(label: "B", gate: "b")
      open_menu_via_keyboard
      Primer::RequestGate.wait_until_started("b")
      assert_spinner_focused

      Primer::RequestGate.release("b")
      assert_focused_text "B"
    end

    def test_refresh_closed_preload_fetches_immediately
      # Starting state: loaded, closed (preload)
      visit_preview(:deferred_refresh, preload: true)
      load_and_close_menu

      set_menu_src(label: "B", gate: "b")
      Primer::RequestGate.wait_until_started("b")
      assert_selector "action-menu:not([data-ready])", visible: :all
      refute_selector "anchored-position:popover-open"

      Primer::RequestGate.release("b")
      assert_selector "action-menu[data-ready=true]", visible: :all
      refute_selector "anchored-position:popover-open"

      click_on_invoker_button
      assert_item "B"
      refute_selector "action-menu include-fragment", visible: :all
      assert_equal 1, Primer::RequestGate.count("b")
    end

    def test_refresh_method_reloads_open_menu
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      load_and_open_menu

      set_menu_src(gate: "r")
      Primer::RequestGate.wait_until_started("r")
      Primer::RequestGate.release("r")
      assert_item "Copy link"
      assert_selector "action-menu[data-ready=true]", visible: :all

      page.execute_script("document.querySelector('action-menu').refresh()")
      Primer::RequestGate.wait_until_started("r", attempt: 2)
      assert_selector "anchored-position:popover-open"
      Primer::RequestGate.release("r", attempt: 2)
      assert_item "Copy link"
      assert_selector "action-menu[data-ready=true]", visible: :all
    end

    def test_refresh_method_on_closed_lazy_menu_waits_for_open
      # Starting state: loaded from gate "r" (attempt 1 released), closed
      visit_preview(:deferred_refresh)
      set_menu_src(gate: "r")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("r")
      Primer::RequestGate.release("r")
      assert_item "Copy link"
      close_menu

      page.execute_script("document.querySelector('action-menu').refresh()")
      # A load inserts its loader synchronously, before any fetch
      assert_no_selector PRIMARY_FRAGMENT, visible: :all, wait: 0
      assert_selector "action-menu .ActionListItem-label", text: "Copy link", visible: :all
      assert_equal 1, Primer::RequestGate.count("r")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("r", attempt: 2)
      Primer::RequestGate.release("r", attempt: 2)
      assert_item "Copy link"
      assert_equal 2, Primer::RequestGate.count("r")
    end

    def test_closed_refresh_during_pending_load_drops_loader_until_open
      # Starting state: closed (lazy) with request A held
      visit_preview(:deferred_refresh)
      load_and_close_menu
      set_menu_src(label: "A", gate: "a")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("a")
      watch_current_fragment("a1")
      close_menu

      page.execute_script("document.querySelector('action-menu').refresh()")
      assert_no_selector "action-menu anchored-position .Overlay-body > include-fragment", visible: :all
      assert_selector "action-menu[data-ready=true]", visible: :all

      Primer::RequestGate.release("a")
      wait_for_fragment_done("a1")
      assert_no_selector "action-menu .ActionListItem-label", exact_text: "A", visible: :all

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("a", attempt: 2)
      Primer::RequestGate.release("a", attempt: 2)
      assert_item "A"
      assert_equal 2, Primer::RequestGate.count("a")
    end

    def test_src_and_refresh_ignored_without_deferred_primary_list
      # A static menu, and one where only a sub-menu is deferred
      [[:default, {}], [:with_deferred_content, { nest_in_sub_menu: true }]].each do |preview, params|
        # Starting state: primary list not deferred, closed
        visit_preview(preview, **params)
        collect_js_errors

        assert_no_alert do
          page.execute_script(<<~JS)
            const menu = document.querySelector('action-menu')
            const fragment = menu.querySelector('include-fragment')
            menu.setAttribute('src', `${fragment ? fragment.getAttribute('src') : '/foo'}?label=Z`)
            menu.refresh()
          JS
        end

        click_on_invoker_button
        find("action-menu .ActionListItem-label", exact_text: "Sub-menu").click if preview == :with_deferred_content
        assert_item "Copy link"
        refute_selector "action-menu .ActionListItem-label", exact_text: "Z"
        if preview == :default
          assert_item "Delete"
          refute_selector "action-menu include-fragment", visible: :all
        end
        assert_empty page.evaluate_script("window.__errors")
      end
    end

    def test_same_src_on_open_failed_menu_retries_at_once
      # Starting state: failed, open
      visit_preview(:deferred_refresh)
      fail_request_while_open

      set_menu_src(gate: "e")
      Primer::RequestGate.wait_until_started("e", attempt: 2)
      assert_selector "anchored-position:popover-open"
      Primer::RequestGate.release("e", attempt: 2)
      assert_item "Copy link"
      assert_equal 2, Primer::RequestGate.count("e")
    end

    def test_same_src_on_closed_lazy_failed_menu_waits_for_open
      # Starting state: failed, closed
      visit_preview(:deferred_refresh)
      fail_request_while_open
      close_menu

      set_menu_src(gate: "e")
      # A retry clears the error class synchronously before refetching
      assert_selector "#{PRIMARY_FRAGMENT}.is-error", visible: :all, wait: 0
      assert_equal 1, Primer::RequestGate.count("e")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("e", attempt: 2)
      Primer::RequestGate.release("e", attempt: 2)
      assert_item "Copy link"
      assert_equal 2, Primer::RequestGate.count("e")
    end

    def test_rewritten_failed_loader_response_is_rejected_and_host_src_reloads
      # Starting state: failed, closed; a morph then rewrites the failed
      # loader's src while the host keeps its own, which upstream fetches
      visit_preview(:deferred_refresh)
      fail_request_while_open
      close_menu
      page.execute_script(<<~JS)
        const loader = #{primary_fragment_js}
        loader.addEventListener('loadend', () => { window.__xDone = true })
        loader.setAttribute('src', loader.getAttribute('src').replace('gate=e', 'label=X&gate=x'))
      JS
      Primer::RequestGate.wait_until_started("x")
      Primer::RequestGate.release("x")
      wait_until { page.evaluate_script("!!window.__xDone") }
      assert_no_selector "action-menu .ActionListItem-label", exact_text: "X", visible: :all

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("e", attempt: 2)
      Primer::RequestGate.release("e", attempt: 2)
      assert_item "Copy link"
      refute_selector "action-menu .ActionListItem-label", exact_text: "X"
    end

    def test_emptied_body_reloads_on_open
      # Starting state: loaded from gate "w", closed (lazy)
      visit_preview(:deferred_refresh)
      set_menu_src(gate: "w")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("w")
      Primer::RequestGate.release("w")
      assert_item "Copy link"
      close_menu
      src = menu_src

      # Other code (eg. a morph of the empty server body) removes the items
      empty_primary_body
      refute_selector "action-menu anchored-position .Overlay-body > *", visible: :all
      assert_equal 1, Primer::RequestGate.count("w")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("w", attempt: 2)
      Primer::RequestGate.release("w", attempt: 2)
      assert_item "Copy link"
      assert_equal 2, Primer::RequestGate.count("w")
      assert_equal src, menu_src
    end

    def test_emptied_body_of_preloaded_menu_reloads_at_once
      # Other code empties the body (eg. a morph of the empty server body), or
      # replaces it with the server's empty one (eg. a Turbo stream) so the
      # mutation targets the overlay, not the body
      %w[empty replace].each do |how|
        # Starting state: loaded, closed (preload)
        gate = "w_#{how}"
        visit_preview(:deferred_refresh, preload: true)
        set_menu_src(gate: gate)
        Primer::RequestGate.wait_until_started(gate)
        Primer::RequestGate.release(gate)
        assert_selector "action-menu[data-ready=true]", visible: :all
        assert_selector "action-menu .ActionListItem-label", exact_text: "Copy link", visible: :all

        if how == "empty"
          empty_primary_body
        else
          page.execute_script(<<~JS)
            const body = document.querySelector('action-menu').overlayBody
            window.__oldBody = body
            body.replaceWith(body.cloneNode(false))
          JS
        end
        Primer::RequestGate.wait_until_started(gate, attempt: 2)
        refute_selector "anchored-position:popover-open"
        Primer::RequestGate.release(gate, attempt: 2)
        assert_selector "action-menu[data-ready=true]", visible: :all
        assert_selector "action-menu .ActionListItem-label", exact_text: "Copy link", visible: :all

        if how == "replace"
          # The items land in the new body, which the menu looks up again
          assert page.evaluate_script(<<~JS)
            (() => {
              const body = document.querySelector('action-menu').overlayBody
              return body !== window.__oldBody && !!body.querySelector('.ActionListItem-label')
            })()
          JS
        end

        click_on_invoker_button
        assert_item "Copy link"
        assert_equal 2, Primer::RequestGate.count(gate)
      end
    end

    def test_emptied_body_drops_pending_response
      # Starting state: loaded, closed with request A held
      visit_preview(:deferred_refresh)
      load_and_close_menu
      set_menu_src(label: "A", gate: "a")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("a")
      # A cancelled replacement fires no include-fragment-replaced, so wait
      # for loadend, which upstream dispatches a task after the replacement
      page.execute_script("#{primary_fragment_js}.addEventListener('loadend', () => { window.__aDone = true })")
      close_menu

      empty_primary_body
      Primer::RequestGate.release("a")
      wait_until { page.evaluate_script("!!window.__aDone") }
      assert_no_selector "action-menu .ActionListItem-label", visible: :all
      # The wiped loader is abandoned, so no load is pending
      assert_selector "action-menu[data-ready=true]", visible: :all

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("a", attempt: 2)
      Primer::RequestGate.release("a", attempt: 2)
      assert_item "A"
      assert_equal 2, Primer::RequestGate.count("a")
    end

    def test_emptied_body_of_open_menu_with_pending_load_reloads_and_stays_open
      # Starting state: loaded, open with request A held
      visit_preview(:deferred_refresh)
      load_and_open_menu
      set_menu_src(label: "A", gate: "a")
      Primer::RequestGate.wait_until_started("a")

      empty_primary_body
      assert_spinner_visible
      # The browser holds a second request for the same URL until the first
      # one completes, so release the abandoned one first
      Primer::RequestGate.release("a")
      Primer::RequestGate.wait_until_started("a", attempt: 2)
      wait_for_frames
      assert_selector "action-menu > anchored-position:popover-open"

      Primer::RequestGate.release("a", attempt: 2)
      assert_item "A"
      assert_equal 2, Primer::RequestGate.count("a")
    end

    def test_empty_response_on_preloaded_menu_reloads_only_on_open
      # Starting state: loaded, closed (preload)
      visit_preview(:deferred_refresh, preload: true)
      assert_selector "action-menu[data-ready=true]", visible: :all

      set_menu_src(empty: "1", gate: "g")
      Primer::RequestGate.wait_until_started("g")
      Primer::RequestGate.release("g")
      assert_selector "action-menu[data-ready=true]", visible: :all
      # Other code changes the invoker, outside the body
      page.execute_script("document.querySelector('action-menu button[aria-controls]').append(document.createElement('span'))")
      # A reload would insert its loader synchronously
      wait_for_frames
      refute_selector "action-menu anchored-position .Overlay-body > *", visible: :all
      assert_equal 1, Primer::RequestGate.count("g")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("g", attempt: 2)
      Primer::RequestGate.release("g", attempt: 2)
      refute_selector "anchored-position:popover-open"
      assert_equal 2, Primer::RequestGate.count("g")
    end

    def test_replaced_body_after_empty_response_reloads_preloaded_menu
      # Starting state: closed (preload), empty response loaded
      visit_preview(:deferred_refresh, preload: true)
      assert_selector "action-menu[data-ready=true]", visible: :all
      set_menu_src(empty: "1", gate: "g")
      Primer::RequestGate.wait_until_started("g")
      Primer::RequestGate.release("g")
      assert_selector "action-menu[data-ready=true]", visible: :all

      # Other code replaces the body with the server's empty one
      page.execute_script(<<~JS)
        const body = document.querySelector('action-menu').overlayBody
        body.replaceWith(body.cloneNode(false))
      JS
      Primer::RequestGate.wait_until_started("g", attempt: 2)
      Primer::RequestGate.release("g", attempt: 2)
      assert_equal 2, Primer::RequestGate.count("g")
    end

    def test_response_without_items_closes_menu_and_is_fetched_again_on_open
      # Starting state: loaded, closed
      visit_preview(:deferred_refresh)
      load_and_close_menu

      set_menu_src(empty_list: "1", gate: "e")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("e")
      Primer::RequestGate.release("e")
      refute_selector "anchored-position:popover-open"
      assert_selector "action-menu button[aria-controls]", focused: true
      # The server rendered an empty list; nothing of it is kept
      refute_selector "action-menu anchored-position .Overlay-body > *", visible: :all
      assert_selector "action-menu[data-ready=true]", visible: :all

      # The empty body is fetched again on open; hold it so the popover is
      # observed open before the (empty) response could close it
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("e", attempt: 2)
      assert_selector "anchored-position:popover-open"
      page.execute_script("document.body.setAttribute('tabindex', '-1'); document.body.focus()")
      refute_selector "anchored-position:popover-open"
      Primer::RequestGate.release("e", attempt: 2)
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_equal 2, Primer::RequestGate.count("e")

      # The menu recovers once the src returns items
      set_menu_src(label: "B")
      click_on_invoker_button
      assert_item "B"
    end

    def test_external_fragment_adopted
      # Other code replaces the body's children, or the body itself, with a
      # loader for a new src
      %w[children body].each do |what|
        # Starting state: loaded, closed
        visit_preview(:deferred_refresh)
        stash_spinner_markup
        load_and_close_menu

        if what == "children"
          insert_external_fragment("label=X")
        else
          page.execute_script(<<~JS)
            const menu = document.querySelector('action-menu')
            const oldBody = menu.overlay.querySelector('.Overlay-body')
            const newBody = oldBody.cloneNode(false)
            const fragment = document.createElement('include-fragment')
            fragment.setAttribute('src', `${menu.getAttribute('src').split('?')[0]}?label=X`)
            fragment.setAttribute('loading', 'eager')
            fragment.innerHTML = window.__spinner
            newBody.append(fragment)
            oldBody.replaceWith(newBody)
          JS
        end
        assert_selector "action-menu[src$='?label=X']", visible: :all
        assert_selector "action-menu[data-ready=true]", visible: :all

        click_on_invoker_button
        assert_item "X"
        close_menu

        set_menu_src(label: "Y")
        click_on_invoker_button
        assert_selector "action-menu anchored-position:popover-open .Overlay-body .ActionListItem-label", exact_text: "Y"

        body_count = page.evaluate_script(<<~JS)
          (() => {
            const overlay = document.querySelector('action-menu').overlay
            return Array.from(overlay.querySelectorAll('.Overlay-body')).filter(b => b.closest('anchored-position') === overlay).length
          })()
        JS
        assert_equal 1, body_count, "replaced #{what}"
      end
    end

    def test_external_lazy_fragment_same_src_loads_on_reopen
      # Starting state: loaded, closed
      visit_preview(:deferred_refresh)
      stash_spinner_markup
      load_and_close_menu
      src = menu_src

      insert_external_fragment(nil, loading: "lazy")
      assert_selector "#{PRIMARY_FRAGMENT}[src='#{src}']", visible: :all

      click_on_invoker_button
      assert_item "Copy link"
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_equal src, menu_src
    end

    def test_lazy_loader_inserted_by_other_code_loads_on_open
      # Idiomorph-style insertion (connected first, attributes afterwards),
      # or insertion while the menu is detached
      %w[shell_first detached].each do |how|
        # Starting state: loaded, closed (lazy)
        gate = "d_#{how}"
        visit_preview(:deferred_refresh)
        stash_spinner_markup
        load_and_close_menu

        if how == "shell_first"
          shell_first_fragment("label=D&gate=#{gate}")
        else
          detach_menu
          insert_external_fragment("label=D&gate=#{gate}", loading: "lazy", menu_js: "window.__m")
          # adopted while detached: src reflected onto the host, load pending
          assert page.evaluate_script("window.__m.getAttribute('src').endsWith(#{"label=D&gate=#{gate}".to_json})")
          assert page.evaluate_script("!window.__m.hasAttribute('data-ready')")
          reattach_menu
        end
        assert_selector "action-menu[src$='label=D&gate=#{gate}']", visible: :all
        assert_equal 0, Primer::RequestGate.count(gate)

        click_on_invoker_button
        Primer::RequestGate.wait_until_started(gate)
        Primer::RequestGate.release(gate)
        assert_item "D"
        assert_selector "action-menu[data-ready=true]", visible: :all
        assert_equal 1, Primer::RequestGate.count(gate)
      end
    end

    def test_same_src_shell_first_fragment_loads_in_open_menu
      # Starting state: loaded from gate "s", open
      visit_preview(:deferred_refresh)
      stash_spinner_markup
      set_menu_src(gate: "s")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("s")
      Primer::RequestGate.release("s")
      assert_item "Copy link"

      # Idiomorph-style insertion with the src the host already has
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        const f = document.createElement('include-fragment')
        menu.overlayBody.append(f)
        f.setAttribute('loading', 'lazy')
        f.setAttribute('src', menu.getAttribute('src'))
        f.innerHTML = window.__spinner
      JS
      Primer::RequestGate.wait_until_started("s", attempt: 2)
      Primer::RequestGate.release("s", attempt: 2)
      assert_item "Copy link"
      assert_selector "action-menu > anchored-position:popover-open"
      assert_equal 2, Primer::RequestGate.count("s")
    end

    def test_external_fragment_adopted_while_open_stays_open
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      stash_spinner_markup
      load_and_open_menu

      insert_external_fragment("label=X&gate=x")
      Primer::RequestGate.wait_until_started("x")
      assert_spinner_focused
      wait_for_frames
      assert_selector "anchored-position:popover-open"
      assert_spinner_focused

      Primer::RequestGate.release("x")
      assert_focused_text "X"
      assert_selector "anchored-position:popover-open"
      assert_selector "action-menu[src$='?label=X&gate=x']", visible: :all
    end

    def test_external_loader_supersedes_pending_open_refresh
      # The external loader replaces the body's children, or is put after or
      # before the pending loader
      %i[replace append prepend].each do |mode|
        # Starting state: loaded, open with request B held
        b = "b_#{mode}"
        c = "c_#{mode}"
        visit_preview(:deferred_refresh)
        stash_spinner_markup
        load_and_open_menu

        set_menu_src(label: "B", gate: b)
        Primer::RequestGate.wait_until_started(b)
        assert_spinner_focused
        watch_current_fragment("B")

        insert_external_fragment("label=C&gate=#{c}", append: mode == :append, prepend: mode == :prepend)
        assert_selector "action-menu[src$='label=C&gate=#{c}']", visible: :all
        Primer::RequestGate.wait_until_started(c)
        assert_spinner_focused
        wait_for_frames
        assert_selector "anchored-position:popover-open"
        assert_spinner_focused

        Primer::RequestGate.release(b)
        wait_for_fragment_done("B")
        refute_selector "action-menu .ActionListItem-label", exact_text: "B", visible: :all
        assert_selector "action-menu:not([data-ready])", visible: :all
        assert_selector "anchored-position:popover-open"

        Primer::RequestGate.release(c)
        assert_focused_text "C"
        assert_selector "anchored-position:popover-open"
        assert_selector "action-menu action-list", count: 1
        assert_equal 1, Primer::RequestGate.count(c)
      end
    end

    def test_refresh_response_with_deferred_sub_menu_not_adopted
      # Starting state: loaded, closed
      visit_preview(:deferred_refresh)
      load_and_close_menu

      set_menu_src(deferred_sub: "1", sub_gate: "s")
      expected_src = menu_src

      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_item "Copy link"
      assert_item "Deferred more"

      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      assert_equal expected_src, menu_src
    end

    def test_morphed_pending_loader_does_not_render_stale_response
      # Starting state: loaded, open with request A held
      visit_preview(:deferred_refresh)
      load_and_open_menu
      set_menu_src(label: "A", gate: "a")
      Primer::RequestGate.wait_until_started("a")
      watch_current_fragment("a1")
      close_menu
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        const b = menu.getAttribute('src').replace('label=A&gate=a', 'label=B&gate=b')
        #{primary_fragment_js}.setAttribute('src', b)   // the morph rewrites the pending loader
        menu.setAttribute('src', b)
      JS
      Primer::RequestGate.release("a")
      wait_for_fragment_done("a1")
      assert_no_selector "action-menu .ActionListItem-label", text: "A", visible: :all
      # The closed lazy menu dropped the pending loader; B starts on open
      assert_selector "action-menu[data-ready=true]", visible: :all

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("b")
      Primer::RequestGate.release("b")
      assert_item "B"
      assert_equal 1, Primer::RequestGate.count("b")
    end

    def test_completion_does_not_mark_a_newer_request_ready
      # Starting state: loaded, open with request A held
      visit_preview(:deferred_refresh)
      load_and_open_menu
      set_menu_src(label: "A", gate: "a")
      Primer::RequestGate.wait_until_started("a")

      # A consumer starts request B as soon as A's first item takes focus
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        const base = menu.getAttribute('src').split('?')[0]
        menu.addEventListener('focusin', event => {
          if (event.target.textContent.trim() === 'A') menu.setAttribute('src', `${base}?label=B&gate=b`)
        }, {once: false})
      JS
      Primer::RequestGate.release("a")
      Primer::RequestGate.wait_until_started("b")
      assert_selector "action-menu:not([data-ready])", visible: :all

      Primer::RequestGate.release("b")
      assert_item "B"
      assert_selector "action-menu[data-ready=true]", visible: :all
    end

    def test_src_changed_while_spinner_takes_focus_keeps_the_newer_load
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      load_and_open_menu

      # A consumer starts request B when the spinner of request A takes focus
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        const base = menu.getAttribute('src').split('?')[0]
        let done = false
        menu.addEventListener('focusin', event => {
          if (done || !event.target.closest('include-fragment')) return
          done = true
          menu.setAttribute('src', `${base}?label=B&gate=b`)
        })
      JS
      set_menu_src(label: "A", gate: "a")
      Primer::RequestGate.wait_until_started("b")
      assert_selector "action-menu > anchored-position:popover-open"

      Primer::RequestGate.release("b")
      assert_item "B"
      assert_equal 1, Primer::RequestGate.count("b")
    end

    def test_out_of_order_stale_first
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      start_out_of_order_requests

      Primer::RequestGate.release("a")
      wait_for_fragment_done("A")
      refute_selector "action-menu .ActionListItem-label", exact_text: "A"
      assert_selector "action-menu:not([data-ready])", visible: :all

      Primer::RequestGate.release("b")
      assert_item "B"
      assert_selector "action-menu[data-ready=true]", visible: :all
    end

    def test_out_of_order_stale_last
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      start_out_of_order_requests

      Primer::RequestGate.release("b")
      assert_item "B"
      assert_selector "action-menu[data-ready=true]", visible: :all

      Primer::RequestGate.release("a")
      wait_for_fragment_done("A")
      refute_selector "action-menu .ActionListItem-label", exact_text: "A"
      assert_item "B"
      assert_selector "action-menu action-list", count: 1
      assert_focused_text "B"
    end

    def test_cancelled_replacement_keeps_loader_until_next_load
      # After the cancelled replacement the menu is reopened, or its src changes
      %w[reopen src_change].each do |ending|
        # Starting state: loaded, closed; a capturing listener cancels the next
        # include-fragment-replace (upstream dispatches it without bubbles)
        gate = "k_#{ending}"
        visit_preview(:deferred_refresh)
        load_and_close_menu
        page.execute_script(<<~JS)
          window.__cancelled = false
          document.addEventListener('include-fragment-replace', (e) => {
            if (!e.target.closest('action-menu')) return
            e.preventDefault()
            window.__cancelled = true
          }, {capture: true, once: true})
        JS
        set_menu_src(label: "B", gate: gate)
        click_on_invoker_button
        Primer::RequestGate.wait_until_started(gate)
        Primer::RequestGate.release(gate)
        wait_until { page.evaluate_script("window.__cancelled === true") }
        assert_selector PRIMARY_FRAGMENT, visible: :all, wait: 0 # loader still in the body
        assert_spinner_visible
        refute_selector "action-menu .ActionListItem-label", exact_text: "B"
        assert_selector "action-menu:not([data-ready])", visible: :all
        close_menu

        if ending == "reopen"
          click_on_invoker_button
          Primer::RequestGate.wait_until_started(gate, attempt: 2)
          Primer::RequestGate.release(gate, attempt: 2)
          assert_item "B"
          assert_equal 2, Primer::RequestGate.count(gate)
        else
          set_menu_src(label: "C")
          click_on_invoker_button
          assert_item "C"
          assert_selector "action-menu[data-ready=true]", visible: :all
          assert_equal 1, Primer::RequestGate.count(gate)
        end
      end
    end

    def test_loaded_primary_menu_keeps_tab_stop
      # Starting state: unloaded, request held, open with its spinner focused
      visit_preview(:deferred_refresh)
      set_menu_src(gate: "p")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("p")
      assert_spinner_focused

      Primer::RequestGate.release("p")
      assert_item "Copy link"
      wait_for_frames
      assert_focused_text "Copy link"
      assert_selector ":focus[tabindex='0']"
    end

    # Holds the first load until its spinner has focus, then lets a consumer
    # listener on the loader's completion focus `target_js` before releasing.
    def complete_load_with_consumer_focus(target_js)
      visit_preview(:deferred_refresh)
      set_menu_src(gate: "p")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("p")
      assert_spinner_focused
      page.execute_script(<<~JS)
        #{primary_fragment_js}.addEventListener('include-fragment-replaced', () => (#{target_js}).focus())
      JS
      Primer::RequestGate.release("p")
      # Focus moved outside closes the menu, so the items may be hidden
      assert_selector "action-menu .ActionListItem-label", exact_text: "Copy link", visible: :all
      wait_for_frames
    end

    def menu_item_js(label)
      "[...document.querySelectorAll('action-menu [role=menuitem]')].find(i => i.textContent.trim() === #{label.to_json})"
    end

    def test_consumer_focus_outside_menu_during_completion_is_kept
      # Starting state: unloaded, request held, open with its spinner focused
      complete_load_with_consumer_focus("document.getElementById('deferred-refresh-button')")

      assert_focused_text "Refresh"
    end

    def test_consumer_focus_on_an_item_during_completion_is_kept
      # Starting state: unloaded, request held, open with its spinner focused
      complete_load_with_consumer_focus(menu_item_js("Quote reply"))

      assert_focused_text "Quote reply"
      assert_selector ":focus[tabindex='0']"
    end

    def test_consumer_focus_on_first_item_during_completion_keeps_tab_stop
      # Starting state: unloaded, request held, open with its spinner focused
      complete_load_with_consumer_focus(menu_item_js("Copy link"))

      assert_focused_text "Copy link"
      assert_selector ":focus[tabindex='0']"
    end

    def test_refresh_open_menu_in_place
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      load_and_open_menu

      set_menu_src(label: "B", gate: "b")
      Primer::RequestGate.wait_until_started("b")
      assert_selector "anchored-position:popover-open"
      assert_spinner_focused

      Primer::RequestGate.release("b")
      assert_focused_text "B"
      assert_selector "anchored-position:popover-open"
      assert_selector "action-menu action-list", count: 1
    end

    def test_open_refresh_keeps_closed_policy_lazy
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      load_and_open_menu

      set_menu_src(label: "B")
      assert_focused_text "B"
      close_menu

      set_menu_src(label: "C", gate: "c")
      # A load inserts its loader synchronously, before any fetch
      assert_no_selector PRIMARY_FRAGMENT, visible: :all, wait: 0
      assert_equal 0, Primer::RequestGate.count("c")
      assert_selector "action-menu .ActionListItem-label", exact_text: "B", visible: :all

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("c")
      Primer::RequestGate.release("c")
      assert_item "C"
    end

    def test_refresh_with_open_sub_menu
      # Starting state: loaded (with a static sub-menu), open, sub-menu open
      visit_preview(:deferred_refresh)
      set_menu_src(with_sub_menu: "1")
      open_menu_via_keyboard
      assert_selector "action-menu[data-ready=true]", visible: :all

      arrow_down_to("More")
      keyboard.type(:right)
      assert_focused_text "Sub one"

      set_menu_src(with_sub_menu: "1", label: "B")
      assert_focused_text "B"
      assert_selector ":popover-open", count: 1, visible: :all
      assert_selector "action-menu > anchored-position:popover-open"

      keyboard.type(:down)
      assert_focused_text "Copy link"

      arrow_down_to("More")
      keyboard.type(:right)
      assert_focused_text "Sub one"
      keyboard.type(:down)
      assert_focused_text "Sub two"
      keyboard.type(:tab)
      # focus is in the sub-menu, not the primary overlay
      assert_selector "action-menu > anchored-position anchored-position :focus"

      keyboard.type(:left)
      refute_selector "[role=menuitem]", text: "Sub one"
      keyboard.type(:escape)
      refute_selector "anchored-position:popover-open"
      assert_no_selector "[data-focus-trap=active]", visible: :all
    end

    def test_refresh_while_item_dialog_open
      # Starting state: loaded, open
      visit_preview(:deferred_refresh)
      load_and_open_menu

      find("action-menu [role=menuitem]", text: "Show dialog").click
      assert_selector "dialog[open]"

      set_menu_src(label: "B")
      close_dialog
      refute_selector "dialog[open]"

      click_on_invoker_button
      assert_item "B"
    end

    def test_reattach_before_pending_request_completes
      # Starting state: loaded, closed (preload)
      visit_preview(:deferred_refresh, preload: true)
      load_and_close_menu

      set_menu_src(label: "B", gate: "b")
      Primer::RequestGate.wait_until_started("b")
      detach_menu
      reattach_menu

      Primer::RequestGate.release("b")
      assert_selector "action-menu[data-ready=true]", visible: :all

      click_on_invoker_button
      assert_item "B"
    end

    def test_completion_while_detached
      # Starting state: loaded, closed (preload)
      visit_preview(:deferred_refresh, preload: true)
      collect_js_errors
      load_and_close_menu

      set_menu_src(label: "B", gate: "b")
      Primer::RequestGate.wait_until_started("b")
      detach_menu

      Primer::RequestGate.release("b")
      wait_until { detached_menu_has_label?("B") }
      assert_empty page.evaluate_script("window.__errors")
      reattach_menu
      assert_selector "action-menu[data-ready=true]", visible: :all

      click_on_invoker_button
      assert_item "B"
      close_menu

      set_menu_src(label: "C")
      click_on_invoker_button
      assert_item "C"
    end

    def test_failure_while_detached_retries_once_on_open
      # Starting state: loaded, open (lazy)
      visit_preview(:deferred_refresh)
      load_and_open_menu

      fail_request_while_detached
      reattach_menu
      # a retry on reconnect would have stripped is-error in #sync
      assert page.evaluate_script("!!window.__m.querySelector('anchored-position .Overlay-body > include-fragment.is-error')")

      click_on_invoker_button
      Primer::RequestGate.wait_until_started("e", attempt: 2)
      Primer::RequestGate.release("e", attempt: 2)
      assert_item "Copy link"
      assert_selector "action-menu[data-ready=true]", visible: :all
      close_menu

      click_on_invoker_button
      assert_item "Copy link"
      assert_equal 2, Primer::RequestGate.count("e")
    end

    def test_src_changed_while_detached_preload_fetches_once_on_reattach
      # Starting state: loaded, closed (preload)
      visit_preview(:deferred_refresh, preload: true)
      load_and_close_menu

      detach_menu
      page.execute_script(<<~JS)
        const base = window.__m.getAttribute('src').split('?')[0]
        window.__m.setAttribute('src', `${base}?label=C&gate=c`)
      JS
      assert page.evaluate_script("!!window.__m.querySelector('anchored-position .Overlay-body > include-fragment')")
      wait_for_frames
      assert_equal 0, Primer::RequestGate.count("c")

      reattach_menu
      Primer::RequestGate.wait_until_started("c")
      Primer::RequestGate.release("c")
      assert_selector "action-menu[data-ready=true]", visible: :all

      click_on_invoker_button
      assert_item "C"
      assert_equal 1, Primer::RequestGate.count("c")
    end

    def test_src_changed_while_detached_removes_pending_loader
      # Starting state: loaded, open with request A held; closed; detached
      visit_preview(:deferred_refresh)
      load_and_open_menu
      set_menu_src(label: "A", gate: "a")
      Primer::RequestGate.wait_until_started("a")
      watch_current_fragment("a1")
      close_menu
      detach_menu

      page.execute_script("window.__m.setAttribute('src', window.__m.getAttribute('src').replace('label=A&gate=a', 'label=B&gate=b'))")
      assert_equal false, page.evaluate_script("!!window.__m.querySelector('anchored-position .Overlay-body > include-fragment')")
      Primer::RequestGate.release("a")
      wait_for_fragment_done("a1")
      refute detached_menu_has_label?("A")

      reattach_menu
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("b")
      Primer::RequestGate.release("b")
      assert_item "B"
      assert_equal 1, Primer::RequestGate.count("b")
    end

    def test_reattach_twice_leaves_one_invoker_observation_and_no_extra_scroll_listeners
      # Starting state: closed, not loaded (lazy)
      visit_preview(:deferred_refresh)
      page.execute_script(<<~JS)
        window.__scroll = new Set()
        const add = window.addEventListener.bind(window), remove = window.removeEventListener.bind(window)
        window.addEventListener = (type, fn, opts) => { if (type === 'scroll') window.__scroll.add(fn); return add(type, fn, opts) }
        window.removeEventListener = (type, fn, opts) => { if (type === 'scroll') window.__scroll.delete(fn); return remove(type, fn, opts) }
        window.__targets = new Map()   // target -> Set of observers
        const observe = IntersectionObserver.prototype.observe, unobserve = IntersectionObserver.prototype.unobserve, disconnect = IntersectionObserver.prototype.disconnect
        const forget = (observer) => { for (const set of window.__targets.values()) set.delete(observer) }
        IntersectionObserver.prototype.observe = function (t) { (window.__targets.get(t) ?? window.__targets.set(t, new Set()).get(t)).add(this); return observe.call(this, t) }
        IntersectionObserver.prototype.unobserve = function (t) { window.__targets.get(t)?.delete(this); return unobserve.call(this, t) }
        IntersectionObserver.prototype.disconnect = function () { forget(this); return disconnect.call(this) }
        window.__invokerObservers = () => window.__targets.get(document.querySelector('action-menu').invokerElement)?.size ?? 0
      JS

      2.times { detach_menu; reattach_menu; wait_for_frames }
      after_two = page.evaluate_script("window.__scroll.size")
      assert_equal 1, page.evaluate_script("window.__invokerObservers()")

      detach_menu; reattach_menu; wait_for_frames
      # anchored-position shares the window scroll set, so only growth counts
      assert_equal after_two, page.evaluate_script("window.__scroll.size")
      assert_equal 1, page.evaluate_script("window.__invokerObservers()")

      detach_menu; wait_for_frames
      # the menu's own scroll listener goes; relies on anchored-position
      # keeping its module-level scroll listener across disconnect
      assert_equal after_two - 1, page.evaluate_script("window.__scroll.size")
      assert_equal 0, page.evaluate_script("window.__targets.get(window.__m.invokerElement)?.size ?? 0")
    end

    def test_replaced_overlay_releases_old_sub_menu_trap
      # Starting state: loaded (with a static sub-menu), open, sub-menu open
      visit_preview(:deferred_refresh)
      stash_spinner_markup
      set_menu_src(with_sub_menu: "1")
      open_menu_via_keyboard
      assert_selector "action-menu[data-ready=true]", visible: :all

      arrow_down_to("More")
      keyboard.type(:right)
      assert_focused_text "Sub one"
      assert_selector "[data-focus-trap=active]", visible: :all

      # replaces the whole primary overlay, open sub-menu included
      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        const old = menu.overlay
        const replacement = old.cloneNode(true)
        const body = Array.from(replacement.querySelectorAll('.Overlay-body')).find(b => b.closest('anchored-position') === replacement)
        const fragment = document.createElement('include-fragment')
        fragment.setAttribute('src', `${menu.getAttribute('src').split('?')[0]}?label=N`)
        fragment.setAttribute('loading', 'eager')
        fragment.innerHTML = window.__spinner
        body.replaceChildren(fragment)
        window.__oldOverlay = old
        old.replaceWith(replacement)
      JS
      assert_selector "action-menu[src$='?label=N']", visible: :all
      assert_selector "action-menu[data-ready=true]", visible: :all

      click_on_invoker_button
      assert_item "N"
      close_menu

      assert_no_selector "[data-focus-trap=active]", visible: :all
      assert_equal 0, page.evaluate_script("window.__oldOverlay.querySelectorAll('[data-focus-trap=active]').length")
    end

    def test_replaced_overlay_of_static_menu_releases_old_sub_menu_trap
      # Starting state: static menu open, sub-menu open
      visit_preview(:with_actions, nest_in_sub_menu: true)
      open_menu_via_keyboard
      activate_via_enter # expand sub-menu
      assert_selector("##{sub_menu_id}:popover-open")
      assert_selector "[data-focus-trap=active]", visible: :all

      page.execute_script(<<~JS)
        const menu = document.querySelector('action-menu')
        const old = menu.overlay
        window.__oldOverlay = old
        old.replaceWith(old.cloneNode(true))
      JS
      wait_for_frames
      assert_equal 0, page.evaluate_script("window.__oldOverlay.querySelectorAll('[data-focus-trap=active]').length")
    end

    def test_sub_menu_focus_trap_released_on_close
      visit_preview(:sub_menus)

      open_menu_via_keyboard
      arrow_down_to("Paste special")
      keyboard.type(:right)
      assert_selector("[role=menuitem]", text: "Paste plain text")

      keyboard.type(:left)
      refute_selector("[role=menuitem]", text: "Paste plain text")

      keyboard.type(:escape)
      refute_selector("[role=menuitem]", text: "Paste special")

      assert_no_selector "[data-focus-trap=active]", visible: :all

      # focus returns to the invoker, then Tab must leave the menu
      assert_selector "action-menu button:focus"
      keyboard.type(:tab)
      assert_no_selector "action-menu :focus"
    end

    def test_detach_with_open_sub_menu_releases_trap
      visit_preview(:sub_menus)

      open_menu_via_keyboard
      arrow_down_to("Paste special")
      keyboard.type(:right)
      assert_selector("[role=menuitem]", text: "Paste plain text")

      page.execute_script("window.__detachedMenu = document.querySelector('action-menu'); window.__detachedMenu.remove()")
      page.execute_script("const b = document.createElement('button'); b.id = 'outside-target'; document.body.append(b)")

      assert_no_selector "[data-focus-trap=active]", visible: :all
      assert_equal 0, page.evaluate_script("window.__detachedMenu.querySelectorAll('[data-focus-trap=active]').length")

      keyboard.type(:tab)
      assert_selector "#outside-target:focus"
    end

    def test_default_preload_response_has_no_deferred_sub_menu
      # Starting state: preloaded, closed
      visit_preview(:with_deferred_preloaded_content)
      assert_selector "action-menu[data-ready=true]", visible: :all

      click_on_invoker_button
      assert_item "Copy link"
      refute_selector "action-menu .ActionListItem-label", exact_text: "Deferred more", visible: :all
    end

    # Puts an eager fragment for the deferred response, held by `gate`, at
    # the end of `container_js`
    def insert_foreign_fragment(container_js, gate, empty: false)
      page.execute_script(<<~JS)
        const base = document.querySelector('action-menu').getAttribute('src').split('?')[0]
        const fragment = document.createElement('include-fragment')
        fragment.setAttribute('src', `${base}?gate=#{gate}#{'&empty=1' if empty}`)
        ;(#{container_js}).append(fragment)
      JS
      Primer::RequestGate.wait_until_started(gate)
    end

    def test_fragment_in_a_sub_menu_item_does_not_move_focus
      # Starting state: primary and deferred sub-menu loaded, second sub-menu item focused
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_open_menu
      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      page.execute_script("[...#{sub_menu_js('Deferred more')}.querySelectorAll('[role=menuitem]')].find(i => i.textContent.trim() === 'Quote reply').focus()")

      insert_foreign_fragment("#{sub_menu_js('Deferred more')}.querySelector('.ActionListItem-label')", "x")
      Primer::RequestGate.release("x")
      wait_until(message: "Foreign fragment did not complete") { page.evaluate_script("!#{sub_menu_js('Deferred more')}.querySelector('include-fragment')") }
      wait_for_frames

      assert_focused_text "Quote reply"
    end

    def test_consumer_overlay_in_a_sub_menu_is_not_treated_as_a_sub_menu
      # Starting state: primary and deferred sub-menu loaded, consumer overlay open inside it
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_open_menu
      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      page.execute_script(<<~JS)
        const overlay = document.createElement('anchored-position')
        overlay.id = 'consumer-overlay'
        overlay.setAttribute('popover', 'manual');
        #{sub_menu_js('Deferred more')}.querySelector('ul').append(overlay);
        overlay.showPopover()
      JS

      insert_foreign_fragment("document.getElementById('consumer-overlay')", "y", empty: true)
      Primer::RequestGate.release("y")
      wait_until(message: "Foreign fragment did not complete") { page.evaluate_script("!document.querySelector('#consumer-overlay include-fragment')") }
      wait_for_frames

      assert page.evaluate_script("document.getElementById('consumer-overlay').matches(':popover-open')")
    end

    def test_loaded_sub_menu_focuses_first_visible_item
      # Starting state: primary loaded with a deferred sub-menu whose first group is hidden, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s", sub_hidden_first_group: "1")
      load_and_open_menu

      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      wait_for_frames
      assert_focused_text "Copy link"
      assert sub_menu_open?("Deferred more")
    end

    def test_loaded_primary_menu_focuses_first_visible_item
      # Starting state: unloaded, first group hidden, request held, open with its spinner focused
      visit_preview(:deferred_refresh)
      set_menu_src(hidden_first_group: "1", gate: "p")
      click_on_invoker_button
      Primer::RequestGate.wait_until_started("p")
      assert_spinner_focused

      Primer::RequestGate.release("p")
      assert_item "Copy link"
      wait_for_frames
      assert_focused_text "Copy link"
      assert primary_menu_open?
    end

    # A static menu with two eager deferred sub-menus, "Sub-menu" and
    # "Sub-menu 2", whose requests are held by gates "g1" and "g2"
    def visit_static_menu_with_two_held_sub_menus
      visit_preview(:with_deferred_content, nest_in_sub_menu: true)
      page.execute_script(<<~'JS')
        const menu = document.querySelector('action-menu')
        const parent = menu.parentNode
        menu.remove()
        // The sub-menu's item and its overlay, with the ids renamed
        for (const element of [menu.querySelector('#deferred-button').closest('li'), menu.querySelector('#deferred-overlay')]) {
          element.insertAdjacentHTML('afterend', element.outerHTML.replaceAll('deferred-', 'deferred2-').replace('>Sub-menu<', '>Sub-menu 2<'))
        }
        const base = menu.querySelector('include-fragment').getAttribute('src').split('?')[0]
        menu.querySelectorAll('include-fragment').forEach((fragment, index) => {
          fragment.setAttribute('src', `${base}?gate=g${index + 1}`)
          fragment.setAttribute('loading', 'eager')
        })
        menu.removeAttribute('data-ready')
        parent.append(menu)
      JS
      Primer::RequestGate.wait_until_started("g1")
      Primer::RequestGate.wait_until_started("g2")
    end

    def menu_ready?
      page.evaluate_script("document.querySelector('action-menu').getAttribute('data-ready') === 'true'")
    end

    def test_static_menu_is_ready_only_when_every_deferred_sub_menu_loaded
      # Starting state: static menu, two eager deferred sub-menus held, closed
      visit_static_menu_with_two_held_sub_menus
      refute menu_ready?

      Primer::RequestGate.release("g2")
      wait_until(message: "Second sub-menu did not load") { page.evaluate_script("document.querySelectorAll('action-menu include-fragment').length === 1") }
      refute menu_ready?

      Primer::RequestGate.release("g1")
      wait_until(message: "Menu not ready") { menu_ready? }
    end

    # Single-select form whose response checks nothing and has an eager
    # deferred sub-menu, held by gate "c", whose item claims the selection
    def load_single_select_form_with_held_sub_menu
      visit_preview(:deferred_refresh_form, select_variant: :single)
      set_menu_src(variant: "single", checked: "", deferred_sub: "1", sub_gate: "c")
      click_on_invoker_button
      assert_selector "action-menu[data-ready=true]", visible: :all
      Primer::RequestGate.wait_until_started("c")
    end

    def release_child_sub_menu
      Primer::RequestGate.release("c")
      assert_selector "action-menu .ActionListItem-label", exact_text: "Old child", visible: :all
      wait_for_frames
    end

    def submitted_value
      find("input[type=submit]").click
      JSON.parse(find("pre").text)["value"]
    end

    def test_late_sub_menu_does_not_override_the_users_choice
      # Starting state: single-select form loaded, nothing checked, sub-menu request held, open
      load_single_select_form_with_held_sub_menu

      find("action-menu .ActionListItem-label", exact_text: "Recursive").click
      refute_selector "anchored-position:popover-open"
      release_child_sub_menu

      assert_selector "action-menu button[aria-controls] .Button-label", text: "Strategy: Recursive"
      assert_equal "recursive", submitted_value
    end

    def test_late_sub_menu_selection_applies_without_a_users_choice
      # Starting state: single-select form loaded, nothing checked, sub-menu request held, open
      load_single_select_form_with_held_sub_menu
      close_menu
      release_child_sub_menu

      assert_selector "action-menu button[aria-controls] .Button-label", text: "Strategy: Old child"
      assert_equal "old_child", submitted_value
    end

    def assert_sub_menu_closed_on_its_item(label)
      wait_until(message: "Sub-menu did not close") { !sub_menu_open?(label) }
      wait_for_frames
      assert_focused_text label
      assert primary_menu_open?
    end

    def test_empty_sub_menu_fetches_again_on_reopen
      # Starting state: primary loaded, deferred sub-menu came back empty and closed, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_empty: "1", sub_gate: "s")
      load_and_open_menu
      open_held_sub_menu "Deferred more", "s"
      assert_sub_menu_closed_on_its_item "Deferred more"

      open_held_sub_menu "Deferred more", "s", attempt: 2
      assert_sub_menu_closed_on_its_item "Deferred more"
      assert_equal 2, Primer::RequestGate.count("s")
    end

    def test_reopened_empty_sub_menu_focuses_its_loaded_items
      # Starting state: primary loaded, deferred sub-menu came back empty once and closed, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_empty_once: "1", sub_gate: "s")
      load_and_open_menu
      open_held_sub_menu "Deferred more", "s"
      assert_sub_menu_closed_on_its_item "Deferred more"

      open_held_sub_menu "Deferred more", "s", attempt: 2
      assert_focus_in_sub_menu "Deferred more"
      wait_for_frames
      assert sub_menu_open?("Deferred more")
    end

    def test_preloaded_empty_sub_menu_fetches_again_when_opened
      # Starting state: primary loaded, preloaded deferred sub-menu came back empty while closed, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_empty: "1", sub_gate: "s", sub_preload: "1")
      load_and_open_menu
      Primer::RequestGate.wait_until_started("s")
      Primer::RequestGate.release("s")
      wait_until(message: "Preload did not complete") { page.evaluate_script("!#{sub_menu_js('Deferred more')}.querySelector('include-fragment')") }

      open_held_sub_menu "Deferred more", "s", attempt: 2
      assert_sub_menu_closed_on_its_item "Deferred more"
    end

    def test_consumer_focus_in_sub_menu_during_completion_is_kept
      # Starting state: primary loaded, sub-menu request held with its spinner focused
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_open_menu
      open_sub_menu "Deferred more"
      Primer::RequestGate.wait_until_started("s")
      assert_spinner_focused
      page.execute_script(<<~JS)
        const subMenu = #{sub_menu_js('Deferred more')};
        subMenu.querySelector('include-fragment').addEventListener('include-fragment-replaced', () => {
          [...subMenu.querySelectorAll('[role=menuitem]')].find(i => i.textContent.trim() === 'Quote reply').focus()
        })
      JS

      Primer::RequestGate.release("s")
      assert_focused_text "Quote reply"
      wait_for_frames
      assert_focused_text "Quote reply"
      assert_selector ":focus[tabindex='0']"
    end

    def test_failed_retry_of_empty_sub_menu_retries_again
      # Starting state: primary loaded, deferred sub-menu came back empty once and closed, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_empty_once: "1", sub_gate: "s")
      load_and_open_menu
      open_held_sub_menu "Deferred more", "s"
      assert_sub_menu_closed_on_its_item "Deferred more"

      open_sub_menu "Deferred more"
      Primer::RequestGate.wait_until_started("s", attempt: 2)
      Primer::RequestGate.release("s", attempt: 2, status: 500)
      wait_until(message: "Retry did not fail") { page.evaluate_script("!!#{sub_menu_js('Deferred more')}.querySelector('include-fragment.is-error')") }
      page.execute_script("#{sub_menu_js('Deferred more')}.hidePopover()")
      wait_until(message: "Sub-menu did not close") { !sub_menu_open?("Deferred more") }

      open_held_sub_menu "Deferred more", "s", attempt: 3
      assert_focus_in_sub_menu "Deferred more"
    end

    def test_static_menu_deferred_sub_menu_focuses_its_first_item
      # Starting state: static primary with a deferred sub-menu, open
      visit_preview(:with_deferred_content, nest_in_sub_menu: true)
      click_on_invoker_button

      open_sub_menu "Sub-menu"
      assert_item "Copy link"
      assert_focus_in_sub_menu "Sub-menu"
      wait_for_frames
      assert sub_menu_open?("Sub-menu")
    end

    def test_static_menu_is_not_ready_while_an_empty_sub_menu_retries
      # Starting state: static menu whose deferred sub-menu came back empty once, closed again, open
      visit_preview(:with_deferred_content, nest_in_sub_menu: true)
      page.execute_script(<<~JS)
        const fragment = document.querySelector('action-menu include-fragment');
        fragment.setAttribute('src', `${fragment.getAttribute('src').split('?')[0]}?gate=r&empty_once=1`)
      JS
      click_on_invoker_button
      open_held_sub_menu "Sub-menu", "r"
      assert_sub_menu_closed_on_its_item "Sub-menu"
      assert menu_ready?

      open_sub_menu "Sub-menu"
      Primer::RequestGate.wait_until_started("r", attempt: 2)
      refute menu_ready?

      Primer::RequestGate.release("r", attempt: 2)
      assert_focus_in_sub_menu "Sub-menu"
      assert menu_ready?
    end

    def test_nested_deferred_sub_menu_keeps_focus
      # Starting state: primary loaded with a deferred sub-menu, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_open_menu

      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      wait_for_frames
      assert sub_menu_open?("Deferred more")
      assert primary_menu_open?
    end

    def test_loaded_deferred_sub_menu_keeps_tab_stop
      # Starting state: primary loaded with a deferred sub-menu, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_open_menu

      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      wait_for_frames
      assert_selector ":focus[tabindex='0']"

      # The sub-menu traps Tab, which wraps back to its item, not to a
      # focus trap sentinel
      keyboard.type(:tab)
      wait_for_frames
      assert_focus_in_sub_menu "Deferred more"
    end

    def test_doubly_nested_deferred_sub_menu_keeps_focus
      # Starting state: primary loaded with two levels of deferred sub-menus, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "2", sub_gate: "s")
      load_and_open_menu

      open_sub_menu "Deferred more (2)"
      assert_focus_in_sub_menu "Deferred more (2)"

      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      wait_for_frames
      assert sub_menu_open?("Deferred more (2)")
      assert sub_menu_open?("Deferred more")
      assert primary_menu_open?
    end

    def test_nested_deferred_sub_menu_keeps_focus_after_reattach
      # Starting state: primary loaded with a deferred sub-menu, moved, closed
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_close_menu
      detach_menu
      reattach_menu

      click_on_invoker_button
      open_held_sub_menu "Deferred more", "s"
      assert_focus_in_sub_menu "Deferred more"
      wait_for_frames
      assert sub_menu_open?("Deferred more")
    end

    def test_empty_nested_deferred_sub_menu_closes_and_refocuses_item
      # Starting state: primary loaded with a deferred sub-menu that responds empty, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_empty: "1", sub_gate: "s")
      load_and_open_menu

      open_held_sub_menu "Deferred more", "s"
      wait_until(message: "Sub-menu did not close") { !sub_menu_open?("Deferred more") }
      wait_for_frames
      assert_focused_text "Deferred more"
      assert primary_menu_open?
    end

    def test_closed_sub_menu_load_does_not_take_focus
      # Starting state: primary loaded, sub-menu request held, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_open_menu
      open_sub_menu "Deferred more"
      Primer::RequestGate.wait_until_started("s")

      close_menu
      Primer::RequestGate.release("s")
      wait_until(message: "Sub-menu did not load") do
        page.evaluate_script("!!#{sub_menu_js('Deferred more')}?.querySelector('[role=menuitem]:not(include-fragment [role=menuitem])')")
      end
      wait_for_frames

      refute_selector "anchored-position:popover-open"
      refute page.evaluate_script("!!document.activeElement?.closest('action-menu anchored-position')")
    end

    def test_sub_menu_load_after_primary_reload_is_ignored
      # Starting state: primary loaded, sub-menu request held, open
      visit_preview(:deferred_refresh)
      set_menu_src(deferred_sub: "1", sub_gate: "s")
      load_and_open_menu
      open_sub_menu "Deferred more"
      Primer::RequestGate.wait_until_started("s")
      page.execute_script(<<~JS)
        #{sub_menu_js('Deferred more')}.querySelector('include-fragment').addEventListener('loadend', () => { window.__oldSubMenuDone = true })
      JS

      page.execute_script("document.querySelector('action-menu').refresh()")
      assert_selector "action-menu[data-ready=true]", visible: :all
      assert_item "Copy link"
      Primer::RequestGate.release("s")
      wait_until(message: "Old sub-menu load did not finish") { page.evaluate_script("!!window.__oldSubMenuDone") }
      wait_for_frames

      assert primary_menu_open?
      assert page.evaluate_script("document.querySelector('action-menu').overlay.contains(document.activeElement)")
    end

    def test_opening_second_menu_closes_first_menu
      visit_preview(:two_menus)

      find("#menu-1-button").click

      assert_selector "action-menu ul li", text: "Eat a dot"
      refute_selector "action-menu ul li", text: "Stomp a turtle"

      # for whatever reason, using Capybara's click method causes the menu to open
      # and then close immediately, so we do it in JS instead
      page.evaluate_script("document.querySelector('#menu-2-button').click()")

      refute_selector "action-menu ul li", text: "Eat a dot"
      assert_selector "action-menu ul li", text: "Stomp a turtle"
    end

    def test_single_select_item_checked
      visit_preview(:single_select)

      click_on_invoker_button
      click_on_second_item

      # clicking item closes menu, so checked item is hidden
      assert_selector "[aria-checked=true]", text: "Recursive", visible: :hidden
    end

    def test_single_select_item_checked_via_keyboard_enter
      visit_preview(:single_select)

      open_menu_via_keyboard
      activate_via_enter

      # activating item closes menu, so checked item is hidden
      assert_selector "[aria-checked=true]", text: "Fast forward", visible: :hidden

      open_menu_via_keyboard
      arrow_down_to("Recursive")
      activate_via_enter

      assert_selector "[aria-checked=true]", text: "Recursive", visible: :hidden
    end

    def test_single_select_item_checked_via_keyboard_space
      visit_preview(:single_select)

      open_menu_via_keyboard

      # "click" on first item
      activate_via_space

      # activating item closes menu, so checked item is hidden
      assert_selector "[aria-checked=true]", text: "Fast forward", visible: :hidden

      open_menu_via_keyboard

      arrow_down_to("Recursive")
      activate_via_space

      assert_selector "[aria-checked=true]", text: "Recursive", visible: :hidden
    end

    def test_single_select_item_unchecks_previously_checked_item
      visit_preview(:single_select)

      click_on_invoker_button
      click_on_third_item

      # clicking item closes menu, so checked item is hidden
      refute_selector "[aria-checked=true]", text: "Recursive", visible: :hidden

      click_on_invoker_button
      click_on_second_item

      # clicking item closes menu, so checked item is hidden
      assert_selector "[aria-checked=true]", text: "Recursive", visible: :hidden
    end

    def test_single_selected_item_cannot_be_unchecked
      visit_preview(:single_select)

      click_on_invoker_button
      click_on_second_item

      click_on_invoker_button
      click_on_second_item

      # clicking item closes menu, so checked item is hidden
      assert_selector "[aria-checked=true]", text: "Recursive", visible: :hidden
    end

    def test_multi_select_items_checked
      visit_preview(:multiple_select)

      click_on_invoker_button
      click_on_second_item
      click_on_third_item

      # clicking item closes menu, so checked item is hidden
      assert_selector "[aria-checked=true]", text: "jonrohan"
      assert_selector "[aria-checked=true]", text: "broccolinisoup"
    end

    def test_multi_select_items_checked_in_sub_menu
      visit_preview(:multiple_select, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item
      click_on_second_item(level: 2)
      click_on_third_item(level: 2)

      # clicking item closes menu, so checked item is hidden
      assert_selector "[aria-checked=true]", text: "jonrohan"
      assert_selector "[aria-checked=true]", text: "broccolinisoup"
    end

    def test_multi_select_items_checked_via_keyboard_enter
      visit_preview(:multiple_select)

      open_menu_via_keyboard

      # select first item
      activate_via_enter(expect_focus_change: false)

      assert_selector "[aria-checked=true]", text: "langermank"

      # select second item
      arrow_down_to("jonrohan")
      activate_via_enter(expect_focus_change: false)

      assert_selector "[aria-checked=true]", text: "langermank"
      assert_selector "[aria-checked=true]", text: "jonrohan"
    end

    def test_multi_select_items_checked_via_keyboard_enter_in_sub_menu
      visit_preview(:multiple_select, nest_in_sub_menu: true)

      open_menu_via_keyboard

      # select first item
      activate_via_enter(expect_focus_change: true)

      # select first item in sub-menu
      # flaky because opening a sub-menu races two focus paths
      retry_block do
        activate_via_enter(expect_focus_change: false)

        assert_selector "[aria-checked=true]", text: "langermank"
      end

      # select second item
      arrow_down_to("jonrohan")
      retry_block do
        activate_via_enter(expect_focus_change: false)

        assert_selector "[aria-checked=true]", text: "langermank"
        assert_selector "[aria-checked=true]", text: "jonrohan"
      end
    end

    def test_multi_select_items_checked_via_keyboard_space
      visit_preview(:multiple_select)

      open_menu_via_keyboard

      # select first item
      activate_via_space(expect_focus_change: false)

      assert_selector "[aria-checked=true]", text: "langermank"

      # select second item
      arrow_down_to("jonrohan")
      activate_via_space(expect_focus_change: false)

      assert_selector "[aria-checked=true]", text: "langermank"
      assert_selector "[aria-checked=true]", text: "jonrohan"
    end

    def test_multi_select_items_checked_via_keyboard_space_in_sub_menu
      visit_preview(:multiple_select, nest_in_sub_menu: true)

      open_menu_via_keyboard
      click_on_first_item

      # select first item in sub-menu
      activate_via_space(expect_focus_change: false)

      assert_selector "[aria-checked=true]", text: "langermank"

      # select second item
      arrow_down_to("jonrohan")
      activate_via_space(expect_focus_change: false)

      assert_selector "[aria-checked=true]", text: "langermank"
      assert_selector "[aria-checked=true]", text: "jonrohan"
    end

    def test_multi_select_items_can_be_unchecked
      visit_preview(:multiple_select)

      click_on_invoker_button
      click_on_second_item
      click_on_third_item

      assert_selector "[aria-checked=true]", text: "jonrohan"
      assert_selector "[aria-checked=true]", text: "broccolinisoup"

      click_on_second_item
      click_on_third_item

      refute_selector "[aria-checked=true]"
    end

    def test_multi_select_items_can_be_unchecked_in_sub_menu
      visit_preview(:multiple_select, nest_in_sub_menu: true)

      click_on_invoker_button
      click_on_first_item
      click_on_second_item(level: 2)
      click_on_third_item(level: 2)

      assert_selector "[aria-checked=true]", text: "jonrohan"
      assert_selector "[aria-checked=true]", text: "broccolinisoup"

      click_on_second_item(level: 2)
      click_on_third_item(level: 2)

      refute_selector "[aria-checked=true]"
    end

    def test_closes_menu_on_focus_out
      visit_preview(:default)

      # open menu
      click_on_invoker_button
      assert_selector "action-menu ul li"

      # focus on invoker element
      focus_on_invoker_button

      # list items should no longer be visible
      refute_selector "action-menu ul li"
    end

    def test_closes_menu_when_open_on_invoker_click
      visit_preview(:default)

      click_on_invoker_button
      assert_selector "action-menu ul li"

      # clicking the invoker a second time should close the menu
      click_on_invoker_button(expect_to_open: false)
      refute_selector "action-menu ul li"
    end

    def test_unhidden_disabled_item_cannot_be_checked
      visit_preview(:single_select)

      click_on_invoker_button
      refute_selector "li[data-item-id=hidden]"

      evaluate_multiline_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.showItem(menu.getItemById('hidden'))
      JS

      assert_selector "li[data-item-id=hidden]"

      click_on_item_by_id("hidden")
      refute_selector "li [aria-checked=true]"
    end

    def test_sub_menu_opens_on_click
      visit_preview(:sub_menus)

      click_on_invoker_button

      refute_selector("[role=menuitem]", text: "Paste plain text")
      click_on_third_item
      assert_selector("[role=menuitem]", text: "Paste plain text")

      refute_selector("[role=menuitem]", text: "Current clipboard")
      click_on_fourth_item(level: 2)
      assert_selector("[role=menuitem]", text: "Current clipboard")
    end

    def test_sub_menu_opens_on_right_arrow
      visit_preview(:sub_menus)

      open_menu_via_keyboard
      arrow_down_to("Paste special")

      refute_selector("[role=menuitem]", text: "Paste plain text")
      keyboard.type(:right)
      assert_selector("[role=menuitem]", text: "Paste plain text")

      arrow_down_to("Paste from")

      refute_selector("[role=menuitem]", text: "Current clipboard")
      keyboard.type(:right)
      assert_selector("[role=menuitem]", text: "Current clipboard")
    end

    def test_sub_menu_closes_on_left_arrow
      visit_preview(:sub_menus)

      open_menu_via_keyboard
      arrow_down_to("Paste special")

      keyboard.type(:right)
      assert_selector("[role=menuitem]", text: "Paste plain text")

      keyboard.type(:left)
      refute_selector("[role=menuitem]", text: "Paste plain text")
    end

    def test_hide_item_via_js_api
      visit_preview(:single_select)

      click_on_invoker_button
      assert_selector "li[data-item-id=recursive]"

      evaluate_multiline_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.hideItem(menu.getItemById('recursive'));
      JS

      refute_selector "li[data-item-id=recursive]"
    end

    def test_show_item_via_js_api
      visit_preview(:single_select)

      click_on_invoker_button
      refute_selector "li[data-item-id=hidden]"

      evaluate_multiline_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.showItem(menu.getItemById('hidden'))
      JS

      assert_selector "li[data-item-id=hidden]"
    end

    def test_disable_item_via_js_api
      visit_preview(:single_select)

      click_on_invoker_button
      refute_selector "li[data-item-id=resolve] [aria-disabled=true]"

      evaluate_multiline_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.disableItem(menu.getItemById('resolve'))
      JS

      assert_selector "li[data-item-id=resolve] [aria-disabled=true]"
    end

    def test_enable_item_via_js_api
      visit_preview(:single_select)

      click_on_invoker_button
      assert_selector "li[data-item-id=disabled] [aria-disabled=true]"

      evaluate_multiline_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.enableItem(menu.getItemById('disabled'))
      JS

      refute_selector "li[data-item-id=disabled] [aria-disabled=true]"
    end

    def test_check_item_via_js_api
      visit_preview(:single_select)

      click_on_invoker_button
      refute_selector "li[data-item-id=recursive] [aria-checked=true]"

      evaluate_multiline_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.checkItem(menu.getItemById('recursive'))
      JS

      click_on_invoker_button
      assert_selector "li[data-item-id=recursive] [aria-checked=true]"
    end

    def test_uncheck_item_via_js_api
      # use multiple_select preview here because single-select menus do not allow unchecking checked items
      visit_preview(:multiple_select)

      click_on_invoker_button
      click_on_item_by_id("jon")

      assert_selector "li[data-item-id=jon] [aria-checked=true]"

      evaluate_multiline_script(<<~JS)
        const menu = document.querySelector('action-menu')
        menu.uncheckItem(menu.getItemById('jon'))
      JS

      refute_selector "li[data-item-id=jon] [aria-checked=true]"
    end

    def test_fires_event_on_activation
      visit_preview(:single_select)

      evaluate_multiline_script(<<~JS)
        window.activatedItemText = null
        window.activatedItemChecked = false

        document.querySelector('action-menu').addEventListener('itemActivated', (event) => {
          window.activatedItemText = event.detail.item.innerText
          window.activatedItemChecked = event.detail.checked
        })
      JS

      click_on_invoker_button
      click_on_first_item

      assert page.evaluate_script("window.activatedItemChecked")
      assert_equal "Fast forward", page.evaluate_script("window.activatedItemText")
    end

    def test_icon_button_arrow_key_navigation_after_keyboard_open
      # Regression test: when the show button is an IconButton (which has a tooltip),
      # opening the menu via Enter key caused the tooltip's toggle event to destroy
      # the focus zone, making arrow key navigation non-functional.
      visit_preview(:with_icon_button)

      focus_on_invoker_button
      activate_via_enter
      assert_selector "anchored-position:popover-open"

      arrow_down_to("Does something else")

      second_item_label = page.evaluate_script(<<~JS)
        document.activeElement?.querySelector('.ActionListItem-label')?.textContent?.trim()
      JS

      assert_equal "Does something else", second_item_label
    end
  end
end
