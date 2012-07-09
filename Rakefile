# Based on  http://obfuscurity.com/2011/11/Sequel-Migrations-on-Heroku
# Gist:	    https://gist.github.com/1409152

namespace :db do
  require 'sequel'
  namespace :migrate do
    Sequel.extension :migration
    if ENV['DATABASE_URL']
      DB = Sequel.connect(ENV['DATABASE_URL'])
    else
      DB = Sequel.connect("postgres://localhost/Qsario")
    end

    desc "Perform migration reset (full erase and migration up)"
    task :reset do
      Sequel::Migrator.run(DB, "migrations", :target => 0)
      Sequel::Migrator.run(DB, "migrations")
      puts "<= Resetting database"
    end

    desc "Perform migration up/down to VERSION"
    task :to do
      version = ENV['VERSION'].to_i
      raise "No VERSION was provided" if version.nil?
      Sequel::Migrator.run(DB, "migrations", :target => version)
      puts "<= Database migrating to version=[#{version}]"
    end

    desc "Perform migration up to latest migration available"
    task :up do
      Sequel::Migrator.run(DB, "migrations")
      puts "<= Migrating database to latest version"
    end

    desc "Perform migration down (erase all data)"
    task :down do
      Sequel::Migrator.run(DB, "migrations", :target => 0)
      puts "<= Undoing all migrations"
    end

  end
end
