# frozen_string_literal: true

require "json"

module Primer
  module ViewComponents
    # :nodoc:
    # :nocov:
    class FilterableTreeViewItemsController < ApplicationController
      # School → Group → People
      SCHOOLS = {
        "Hogwarts" => {
          "Teaching Staff" => [
            "Albus Dumbledore", "Minerva McGonagall", "Severus Snape",
            "Remus Lupin", "Sybill Trelawney", "Pomona Sprout",
            "Filius Flitwick", "Rubeus Hagrid", "Alastor Moody"
          ],
          "Gryffindor" => [
            "Harry Potter", "Hermione Granger", "Ron Weasley",
            "Neville Longbottom", "Ginny Weasley", "Fred Weasley", "George Weasley"
          ],
          "Slytherin" => [
            "Draco Malfoy", "Pansy Parkinson", "Blaise Zabini",
            "Vincent Crabbe", "Gregory Goyle"
          ],
          "Hufflepuff" => [
            "Cedric Diggory", "Hannah Abbott", "Susan Bones", "Ernie Macmillan"
          ],
          "Ravenclaw" => [
            "Luna Lovegood", "Cho Chang", "Padma Patil", "Terry Boot"
          ]
        },
        "Durmstrang Institute" => {
          "Teaching Staff" => [
            "Igor Karkaroff", "Dmitri Smethwyck"
          ],
          "Students" => [
            "Viktor Krum", "Poliakoff", "Stanislav"
          ]
        },
        "Beauxbatons Academy" => {
          "Teaching Staff" => [
            "Olympe Maxime", "Madame Pomfrey"
          ],
          "Students" => [
            "Fleur Delacour", "Gabrielle Delacour", "Céline Montmorency"
          ]
        }
      }.freeze

      def index
        sleep 0.5

        path = JSON.parse(params[:path])
        filter_query = params[:filter_query].to_s.strip.downcase

        school = path[-2]
        group  = path[-1]
        people = SCHOOLS.dig(school, group) || []
        people = people.select { |p| p.downcase.include?(filter_query) } if filter_query.present?

        render(locals: { people: people, path: path })
      end

      def tree
        sleep 0.3

        filter_query  = params[:filter_query].to_s.strip.downcase
        select_variant = params[:select_variant].presence&.to_sym || :multiple

        school_data = SCHOOLS.filter_map do |school, groups|
          filtered_groups = groups.filter_map do |group, people|
            filtered = filter_query.present? ? people.select { |p| p.downcase.include?(filter_query) } : people
            [group, filtered] unless filtered.empty?
          end.to_h
          [school, filtered_groups] unless filtered_groups.empty?
        end.to_h

        render(locals: { school_data: school_data, select_variant: select_variant })
      end
    end
  end
end
