# frozen_string_literal: true

require 'zeitwerk'

loader = ::Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/scripts")
loader.setup

build_entry = ::RakeEntry::Build.new(method(:send))
build_entry.declare

# bundle exec rake -T
