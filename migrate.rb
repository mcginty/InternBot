#!/usr/bin/env ruby

require 'rubygems'
require 'sqlite3'

class DuplicateRecordException < Exception
end

def setup_new_db
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
  $new_db.execute_batch(sql)
end

def find_or_insert_user(nick, host, do_insert=false)
  find_stmt = $new_db.prepare("select user_id, nick, host from users " +
                              "where nick=? and host=?")
  insert_stmt = $new_db.prepare("insert into users (nick, host) values (?, ?)")
  user_id = nil

  $new_db.transaction do |db|
    find_res = find_stmt.execute!(nick, host)
    if find_res.length > 1
      raise DuplicateRecordException.new('duplicate user: %s %s' % [nick, host])
    elsif find_res.length == 1
      user_id = find_res[0][0]
    elsif do_insert
      insert_stmt.execute!(nick, host)
      user_id = $new_db.last_insert_row_id()
    end
  end
  user_id
end

def migrate_table(table_name)
  stmt = $old_db.prepare("select nick, host from %s" % [table_name])
  sel_stmt = $new_db.prepare("select user_id from %s where user_id=?" % [table_name])
  ins_stmt = $new_db.prepare("insert into %s (user_id) values (?)" % [table_name])

  puts "migrating table %s" % [table_name]

  stmt.execute() do |result|
    result.each do |row|
      nick = row[0]
      host = row[1]
      user_id = find_or_insert_user(nick, host, do_insert=true)
      sel_res = sel_stmt.execute!(user_id)
      if sel_res.length == 0
        ins_stmt.execute!(user_id)
      end
    end
  end
end

def migrate_bros()
  get_stmt = $old_db.prepare("select bro_id, bro from bros")
  ins_stmt = $new_db.prepare("insert into bros (bro) values (?)")

  puts "migrating bros"

  get_stmt.execute() do |result|
    result.each do |row|
      bro_id = row[0] # not used
      bro_text = row[1]
      ins_stmt.execute(bro_text)
    end
  end
end
      
if ARGV.length < 2
  puts "<progname> old.db new.db" % [cmdname]
end

old_db_file = ARGV[0]
new_db_file = ARGV[1]

$old_db = SQLite3::Database.new(old_db_file)
$new_db = SQLite3::Database.new(new_db_file)
setup_new_db()
migrate_table('ops')
migrate_table('voices')
migrate_bros()
