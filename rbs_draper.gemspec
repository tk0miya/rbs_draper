# frozen_string_literal: true

require_relative "lib/rbs_draper/version"

Gem::Specification.new do |spec|
  spec.name = "rbs_draper"
  spec.version = RbsDraper::VERSION
  spec.authors = ["Takeshi KOMIYA"]
  spec.email = ["i.tkomiya@gmail.com"]

  spec.summary = "A RBS files generator for Draper decorators"
  spec.description = "A RBS files generator for Draper decorators"
  spec.homepage = "https://github.com/tk0miya/rbs_draper"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport"
  spec.add_dependency "draper"
  spec.add_dependency "fileutils"
  spec.add_dependency "rbs", ">= 3.8.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
