require 'rubygems'
require 'java'
require 'sequel'
require 'sequel/plugins/optimistic_locking'
Sequel.extension :pagination
Sequel.extension :core_extensions


# Turn off the 'after_commit' and 'after_rollback' hooks on Sequel::Model.
# We don't use them anywhere, and they would otherwise cause a pair of
# blocks to be stored in memory every time we call '.save' (which in turn
# capture the record being saved and stop it being GC'd until the
# transaction finally commits).  When we're doing large batch imports (and
# committing at the end) that's a lot of memory!
Sequel::Model.use_after_commit_rollback = false


require "db/db_migrator"

require 'fileutils'
require "jsonmodel"
require "asutils"
require "asconstants"
require_relative 'exceptions'
require_relative 'logging'
require 'config/config-distribution'
require_relative 'username'


class ASpaceEnvironment

  def self.environment
    @environment
  end


  def self.init(environment = :auto)
    return if @environment      # Already initialised

    if environment != :auto
      @environment = environment
    else
      if ENV["ASPACE_INTEGRATION"] == "true"
        @environment = :integration
      else
        @environment = :production
      end
    end

    prepare_database
  end


  def self.demo_db?
    AppConfig[:db_url] =~ /aspacedemo=true/
  end


  def self.prepare_database
    if @environment == :integration && demo_db?
      # For integration, use an in-memory database instead.
      AppConfig[:db_url] = "jdbc:derby:memory:integrationdb;create=true;aspacedemo=true"
    end

    if @environment != :unit_test
      FileUtils.mkdir_p(AppConfig[:data_directory])

      if demo_db?
        # Try to discourage Derby from locking whole tables.
        java.lang.System.set_property("derby.locks.escalationThreshold", "2147483647")

        Sequel.connect(AppConfig[:db_url]) do |db|
          puts "Running database migrations for demo database"
          DBMigrator.setup_database(db)
          puts "All done."
        end

        puts <<EOF

************************************************************************
***
*** WARNING: Running against the demo database, which is not intended
*** for production use.
***
*** Please see the README.md file for instructions on configuring MySQL.
***
************************************************************************

EOF
      end
    end
  end

end
