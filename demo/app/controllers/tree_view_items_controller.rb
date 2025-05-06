# frozen_string_literal: true

require "json"

# :nodoc:
class TreeViewItemsController < ApplicationController
  TREE = JSON.parse(File.read(File.join(__dir__, "tree_view_items.json"))).freeze

  def index
    # delay a bit so loading spinners, etc can be seen
    sleep 1

    if params[:fail] == "true"
      head :internal_server_error and return
    end

    path = JSON.parse(params[:path])
    node = path.inject(TREE) do |current, segment|
      current["children"][segment]
    end

    entries = (
      node["children"].keys.map { |label| [label, :directory] } +
      node["files"].map { |label| [label, :file] }
    )

    entries.sort_by!(&:first)

    render(
      locals: {
        entries: entries,
        path: path,
        loader: (params[:loader] || :spinner).to_sym,
        select_variant: (params[:select_variant] || :none).to_sym
      }
    )
  end
end
