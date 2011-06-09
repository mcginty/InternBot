require 'rubygems'
require 'sqlite3'

class InternDB
    @@db = nil
    class << self
        def connect(db)
            @@db = SQLite3::Database.new(db)
        end

        # OPS TABLE
        def add_op(nick, host)
            nick.gsub(/'/, "\\'")
            host.gsub(/'/, "\\'")
            if @@db.execute("select * from ops where nick='#{nick}' and host='#{host}'").length == 0
                @@db.execute("insert into ops (nick, host) values ('#{nick}', '#{host}')")
            end
        end

        def remove_op(user)
            user.gsub(/'/, "\\'")
            @@db.execute("delete from ops where nick='#{nick}'")
        end
        
        def is_op?(nick, host)
            return @@db.execute("select * from ops where nick='#{nick}' and host='#{host}'").length > 0
        end

        # VOICES TABLE
        def add_voice(nick, host)
            nick.gsub(/'/, "\\'")
            host.gsub(/'/, "\\'")
            if @@db.execute("select * from voices where nick='#{nick}' and host='#{host}'").length == 0
                @@db.execute("insert into voices (nick, host) values ('#{nick}', '#{host}')")
            end
        end

        def remove_voice(user)
            user.gsub(/'/, "\\'")
            @@db.execute("delete from voices where nick='#{nick}'")
        end

        def is_voice?(nick, host)
            return @@db.execute("select * from voices where nick='#{nick}' and host='#{host}'").length > 0
        end

        # BROS TABLE
        def add_bro(bro)
            bro = bro.gsub(/'/, "''")
            if @@db.execute("select * from bros where bro='#{bro}'").length == 0
                @@db.execute("insert into bros (bro) values ('#{bro}')")
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
