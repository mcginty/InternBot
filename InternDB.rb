require 'rubygems'
require 'sqlite3'

class DuplicateRecordException < Exception
end

class InternDB
    @@db = nil
    class << self
        def connect(db)
            @@db = SQLite3::Database.new(db)
        end

        def find_or_insert_user(nick, host, do_insert=false)
            find_stmt = @@db.prepare("select user_id, nick, host from users " +
                                     "where nick=? and host=?")
            insert_stmt = @@db.prepare("insert into users (nick, host) " +
                                       "values (?, ?)")
            user_id = nil

            @@db.transaction do |db|
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

        # OPS TABLE
        def add_op(nick, host)
            select_stmt = @@db.prepare("select op_id, user_id from ops " +
                                       "where user_id=?")
            ins_stmt = @@db.prepare("insert into ops (user_id) values (?)")
            user_id = find_or_insert_user(nick, host, do_insert=true)

            nick.gsub(/'/, "\\'")
            host.gsub(/'/, "\\'")

            @@db.transaction do |db|
                select_res = select_stmt.execute!(user_id)
                if select_res.length > 1
                    raise DuplicateRecordException.new('duplicate op, user_id %d' % [user_id])
                elsif select_res.length == 0
                    ins_stmt.execute!(user_id)
                end
            end
        end

        def is_op?(nick, host)
            stmt = @@db.prepare("select op_id from ops where user_id=?")
            user_id = find_or_insert_user(nick, host, do_insert=true)
            res = stmt.execute!(user_id)
            res.length > 0
        end

        # VOICES TABLE
        def add_voice(nick, host)
            select_stmt = @@db.prepare("select voice_id, user_id from voices " +
                                       "where user_id=?")
            ins_stmt = @@db.prepare("insert into voices (user_id) values (?)")
            user_id = find_or_insert_user(nick, host, do_insert=true)

            nick.gsub(/'/, "\\'")
            host.gsub(/'/, "\\'")

            @@db.transaction do |db|
                select_res = select_stmt.execute!(user_id)
                if select_res.length > 1
                    raise DuplicateRecordException.new('duplicate voice, user_id %d' % [user_id])
                elsif select_res.length == 0
                    ins_stmt.execute!(user_id)
                end
            end
        end

        def is_voice?(nick, host)
            sel_stmt = @@db.prepare("select voice_id from voices where user_id=?")
            user_id = find_or_insert_user(nick, host, do_insert=true)
            res = sel_stmt.execute!(user_id)
            res.length > 0
        end

        # BROS TABLE
        def add_bro(bro)
            sel_stmt = @@db.prepare("select bro_id from bros where bro=?")
            ins_stmt = @@db.prepare("insert into bros (bro) values (?)")

            bro.gsub(/'/, "\\'")
            bro.capitalize!

            res = sel_stmt.execute!(bro)
            if res.length == 0
                ins_stmt.execute!(bro)
            end
        end

        def remove_bro(bro)
            bro = bro.gsub(/'/, "''")
            @@db.execute("delete from bros where bro='#{bro}'")
        end

        def random_bro
            bros = @@db.execute("select bro from bros")
            return bros.choice[0]
        end

        def list_bros
            return @@db.execute("select bro from bros")
        end
    end
end
