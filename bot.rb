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
BEGIN TRANSACTION;
CREATE TABLE users (
user_id INTEGER PRIMARY KEY,
nick TEXT,
host TEXT,
last_seen INTEGER);
INSERT INTO "users" VALUES(1,'jakemc','jakemc',NULL);
INSERT INTO "users" VALUES(2,'ckenna','ckenna',NULL);
CREATE TABLE ops (
op_id INTEGER PRIMARY KEY,
user_id INTEGER);
INSERT INTO "ops" VALUES(1,1);
INSERT INTO "ops" VALUES(2,2);
CREATE TABLE voices (
voice_id INTEGER PRIMARY KEY,
user_id INTEGER);
CREATE TABLE bros(
bro_id INTEGER PRIMARY KEY,
bro TEXT);
COMMIT;
SQL
    db.execute_batch(sql)
else
    InternBot.start(opts[:db])
end
