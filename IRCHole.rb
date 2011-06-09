=begin

    IRCHole
    A basic ruby IRC framework to make bots easy shit.
    by Jake McGinty

=end

require 'socket'

class IRCHole

    # ChatHole is our simple IRC middleman. He's an asshole.
    # Initializes with the basic server info. Little explanation needed.
    # Take in all the basic server information and a callback
    #
    def initialize(server, port, nick, channel, command_callback)
        ## Internal
        @debug_enabled = true

        ## Server
        @server = server
        @port = port
        @nick = nick # nickname of the bot
        @channel = channel # channel to troll around in
        @s = nil # socket handle

        ## Bot
        @stfu = FALSE # by default, be a dick
        @command_callback = command_callback # command handler

        ## Channel
        @opped = @voiced = @peons = nil # TODO KEEP TRACK OF OPPED VOICE AND PEON
    end

    def debug(msg)
        if @debug_enabled
            puts msg
        end
    end

    # message to main channel
    #
    def speak(msg, channel=@channel)
        if @s and not @stfu
            @s.puts "PRIVMSG #{channel} :"+2.chr+"#{msg}" # 2.chr = bold char in irc
        end
    end

    # NON-channel message to a specific user
    #
    def privmsg(msg, user)
        if @s
            @s.puts "PRIVMSG #{user} :#{msg}"
        end
    end

    def op(user)
        putraw "MODE #{@channel} +o #{user}"
    end

    def deop(user)
        putraw "MODE #{@channel} -o #{user}"
    end

    def stfu
        @stfu = true
    end

    def wtfu
        @stfu = false
    end

    def putraw(raw)
        @s.puts raw unless not @s
    end

    def getraw
        if @s
            return @s.gets
        else
            return nil
        end
    end

    # main loop, no arguments
    #
    def start
        @s = TCPSocket.open(@server, @port)
        @s.puts "USER internbot 0 * InternBot"
        @s.puts "NICK #{@nick}"
        @s.puts "JOIN #{@channel}"

        # main receive loop
        until @s.eof? do
            msg = @s.gets
            msg_pieces = msg.split(':')
            debug msg
            # stay-alive
            if msg.start_with?("PING")
                pongback = "PONG " + msg.split(":")[1]
                @s.puts pongback
                debug pongback
            # auto-op the oplisted members
            elsif msg.index("JOIN :#{@channel}")
                user_info = msg_pieces[1].split('@')[0].split('!')
                if InternDB.is_op?(user_info[0], user_info[1])
                    @s.puts "MODE #{@channel} +o #{user_info[0]}"
                end
            # command parsing
            elsif msg.index("PRIVMSG #{@channel} :")
                user_info = msg_pieces[1].split('@')[0]
                user_info = user_info.split('!')
                @command_callback.call(false, user_info[0], user_info[1], msg_pieces[2..-1].join(":"))
            elsif msg.index("PRIVMSG #{@nick} :")
                user_info = msg_pieces[1].split('@')[0]
                user_info = user_info.split('!')
                @command_callback.call(true, user_info[0], user_info[1], msg_pieces[2..-1].join(":"))
            end
        end
    end
end
