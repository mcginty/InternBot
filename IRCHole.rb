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
        @ops = []
        @voices = []
        @peons = [] # TODO KEEP TRACK OF OPPED VOICE AND PEON
    end

    def debug(msg)
        if @debug_enabled
            puts msg
        end
    end
    
    def op?(nick)
      @ops.member? nick
    end
    
    def list
      user_list = (@ops << @voices << @peons).flatten
      user_list.delete "internbot"
      return userlist
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

    def voice(user)
        putraw "MODE #{@channel} +v #{user}"
    end

    def devoice(user)
        putraw "MODE #{@channel} -v #{user}"
    end

    def op(user)
        putraw "MODE #{@channel} +o #{user}"
    end

    def deop(user)
        putraw "MODE #{@channel} -o #{user}"
    end

    def punish(user)
        if @voices.index(user) != nil
            devoice user
            return
        end
        @peons.each do |peon|
            if peon == user
                next
            end
            voice peon
        end
        putraw "MODE #{@channel} +m"
    end

    def neutralize
        @voices.each do |user|
            devoice user
        end
        putraw "MODE #{@channel} -m"
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
            # initial userlist
            elsif msg.index("#{@nick} = #{@channel} :")
                userlist = msg_pieces[2].split(' ')
                debug 'userlist: ' + userlist.join(' ')
                userlist.each do |user|
                    if user.start_with? '@' # they're opped
                        @ops << user[1..-1]
                    elsif user.start_with? '+' #they're voiced
                        @voices << user[1..-1]
                    else # they suck
                        @peons << user
                    end
                end
                debug 'ops: ' + @ops.join(' ')
                debug 'voices: ' + @voices.join(' ')
                debug 'peons: ' + @peons.join(' ')
            # auto-op the oplisted members
            elsif msg.index("JOIN :#{@channel}")
                user_info = msg_pieces[1].split('@')[0].split('!')
                @peons << user_info[0] unless user_info[0] == @nick
                if InternDB.is_op?(user_info[0], user_info[1])
                    @s.puts "MODE #{@channel} +o #{user_info[0]}"
                end
            elsif msg.index("LEAVE :#{@channel}")
                user_info = msg_pieces[1].split('@')[0].split('!')
                @ops.delete(user_info[0])
                @voices.delete(user_info[0])
                @peons.delete(user_info[0])
            # command parsing
            elsif msg.index("MODE #{@channel} ")
                parts = msg.split(' ')
                if parts[3] == '+o'
                    @peons.delete(parts[4])
                    @voices.delete(parts[4])
                    @ops << parts[4]
                elsif parts[3] == '-o'
                    @ops.delete(parts[4])
                    @peons << parts[4]
                elsif parts[3] == '+v'
                    @peons.delete(parts[4])
                    @voices << parts[4]
                elsif
                    parts[3] == '-v'
                    @voices.delete(parts[4])
                    @peons << parts[4]
                end
                debug 'ops: ' + @ops.join(' ')
                debug 'voices: ' + @voices.join(' ')
                debug 'peons: ' + @peons.join(' ')
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
