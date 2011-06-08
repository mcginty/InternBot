require 'internbot'
require 'rubygems'
require 'sqlite3'
require 'trollop'

opts = Trollop::options do
    version "InternBot 0.5.0 by Jake McGinty"
    banner <<-EOS
InternBot is the bot that maintains both sanity and insanity in the #intern chatroom.

Usage:
    ruby bot.rb [options]
where [options] are:
EOS
    opt :createdb, "Initialize InternBot's SQLite db", :default => false
    opt :db, "Location of SQLite3 db to use", :default => "ib.db"
end

# code time
if opts[:createdb]
    db = SQLite3::Database.new(opts[:db])
    sql = <<SQL
create table ops (
    op_id INTEGER PRIMARY KEY,
    nick TEXT,
    host TEXT
);

create table bros (
    bro_id INTEGER PRIMARY KEY,
    bro TEXT
);

insert into ops (nick, host) values ( 'jakemc', 'jakemc' );
SQL
    db.execute_batch(sql)
else
    InternBot.start(opts[:db])
end
