require_relative '../lib/doc_analyzer'
require 'byebug'

# This is a one-off script to inject the Availability section into the core, Azure, and GCP docs.
# To change which one, set env var INSPEC_DOC_AVAIL_INJECT to core, azure, or gcp.

PROJECTS = {
  core:  { working_dir:                    '.', repo: 'inspec/inspec',       line_wrap: 0 },
  azure: { working_dir: 'contrib/inspec-azure', repo: 'inspec/inspec-azure', line_wrap: 90 },
  gcp:   { working_dir: 'contrib/inspec-gcp',   repo: 'inspec/inspec-gcp',   line_wrap: 0 },
}

def process
  project = (ENV['INSPEC_DOC_AVAIL_INJECT'] || 'core').to_sym
  release_lister = DocAnalyzer::ReleaseLister.new(PROJECTS[project][:repo], PROJECTS[project][:working_dir])

  Dir.chdir(PROJECTS[project][:working_dir]) do
    Dir.glob(['docs/resources/*.md','docs/resources/*.md.erb']) do |md_filename|
      md_doc = DocAnalyzer::MarkdownDoc.new(md_filename)
      puts "  #{md_doc.name}:"

      release = release_lister.earliest_release_containing_file(md_filename)
      puts "    first_released_in: " + (release ? release : 'unknown')

      cursor = md_doc.find_first_section('Examples', 'Syntax', 'Resource Parameters')
      unless cursor
        warn "Could not find preface section"
        next
      end

      frag = make_availability_section(project, release)
      #md_doc.inject_fragment_before(frag, cursor)
      # new_filename = md_filename.sub(/\.md/, '.new.md')
      #md_doc.write(md_filename, WIDTH)
    end
  end
end

def make_availability_section(project, release)
  case project
  when :azure
    make_azure_availability_section(release)
  when :core
    make_core_availability_section(release)
  when :gcp
    make_gcp_availability_section(release)
  end
end


def make_gcp_availability_section(release)
  md_str = <<~EOMD
    ## Availability

    ### Installation

    This resource is available in the `inspec-gcp` [resource pack](https://www.inspec.io/docs/reference/glossary/#resource-pack).  To use it, add the following to your `inspec.yml` in your top-level profile:

        depends:
          inspec-gcp:
            git: https://github.com/inspec/inspec-gcp.git

    You'll also need to setup your GCP credentials; see the resource pack [README](https://github.com/inspec/inspec-gcp#prerequisites).
    EOMD

  if release
    md_str += <<~EOMD

      ### Version

      This resource first became available in #{release} of the inspec-gcp resource pack.
    EOMD
  end
  md_str
end

def make_azure_availability_section(release)
  md_str = <<~EOMD
    ## Availability

    ### Installation

    This resource is available in the `inspec-azure` [resource pack](https://www.inspec.io/docs/reference/glossary/#resource-pack).  To use it, add the following to your `inspec.yml` in your top-level profile:

        depends:
          inspec-azure:
            git: https://github.com/inspec/inspec-azure.git

    You'll also need to setup your Azure credentials; see the resource pack [README](https://github.com/inspec/inspec-azure#inspec-for-azure).
    EOMD

  if release
    md_str += <<~EOMD

      ### Version

      This resource first became available in #{release} of the inspec-azure resource pack.
    EOMD
  end
  md_str
end

def make_core_availability_section(release)
  md_str = <<~EOMD
    ## Availability

    ### Installation

    This resource is distributed along with InSpec itself. You can use it automatically.
  EOMD

  if release
    md_str += <<~EOMD

      ### Version

      This resource first became available in #{release} of InSpec.
    EOMD
  end
  md_str
end

# Force chdir to project root, regardless of where this file is.
Dir.chdir(File.join(File.dirname(__FILE__), '..', '..')) do
  process
end