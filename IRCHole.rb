# IRCHole
# by Jake McGinty
#
# A basic ruby IRC framework to make bots easy shit.

require 'socket'
require 'uri'

class IRCHole
    # ChatHole is our simple IRC middleman. He's an asshole.
    # Initializes with the basic server info. Little explanation needed.
    @admin_prefix = "sudo"

    def initialize server port nick channel command_callback
        ## Server info
        @server = server
        @port = port
        @nick = nick # nickname of the bot
        @channel = channel # channel to troll around in
        @s = nil # socket handle

        ## Bot info
        @stfu = FALSE # by default, be a dick
        @command_callback = command_callback # command handler

        ## Channel info
        @opped = nil
        @voiced = nil
        @peons = nil

    # message to main channel
    def speak msg
        if @s and not @stfu
            @s.puts "PRIVMSG #{$channel} :"+2.chr+"#{msg}" # 2.chr = bold char in irc
        end
    end

    # NON-channel message to a specific user
    def privmsg user msg
        if @s
            @s.puts "PRIVMSG #{user} :#{msg}"
        end
    end

    # main loop, no arguments
    def start
        @s = TCPSocket.open(@server, @port)
        @s.puts "USER internbot 0 * InternBot"
        @s.puts "NICK #{@nick}"
        @s.puts "JOIN #{@channel}"

        # main receive loop
        until @s.eof? do
            msg = @s.gets
            # stay-alive
            if msg.start_with?("PING")
                pongback = "PONG " + msg.split(":")[1]
                @s.puts pongback
                puts pongback
            # auto-op the oplisted members
            elsif msg.index("JOIN :#{@channel}")
                msg_pieces = msg.split(':')
                user_info = msg_pieces[1].split('@')[0]
                if @oplist.index(user_info) != nil
                    @s.puts "MODE #{@channel} +o #{user_info.split("!")[0]}"
                end
            # command parsing
            elsif msg.index("PRIVMSG #{@channel} :")
                msg_pieces = msg.split(':')
                user_info = msg_pieces[1].split('@')[0]
                user_info = user_info.split('!')
                command_parse(user_info[0], user_info[1], msg_pieces[2..-1].join(":").split(" "))
            end
        end
