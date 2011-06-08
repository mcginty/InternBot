require 'socket'
require 'uri'
require 'IRCHole'

class InternBot
    @@irc = nil
    @@admin_prefix = "sudo "

    @@server = "irc.freenode.net"
    @@port = "6667"
    @@nick = "internbot"
    @@channel = "#internbot"

    @@commands = {
        "face" => {
            :admin => false,
            :args  => 1,
            :func  => lambda { |nick, arg|
                @@irc.putraw "WHOIS #{arg}"
                whois = @@irc.getraw
                if arg == @@nick
                    @@irc.speak "Do I look like a bitch to you?"
                    return
                end
                if whois != ":No"
                    @@irc.speak "#{arg}'s face: https://internal.amazon.com/phone/phone-image.cgi?uid=#{whois}"
                else
                    message "This IRC user is faceless. Find nearest shelter."
                end
            },
        },
        "whois" => {
            :admin => false,
            :args  => 1,
            :func  => lambda { |nick, arg|
                @@irc.putraw "WHOIS #{arg}"
                whois = @@irc.getraw
                if arg == @@irc.nick
                    @@irc.speak "Do I look like a bitch to you?"
                    return
                end
                if whois != ":No"
                    @@irc.speak "#{arg}'s lookup: https://contactstool.amazon.com/ac/can/people/find/#{whois}"
                else
                    message "This IRC user is faceless. Find nearest shelter."
                end
            },
        },
        "op" => {
            :admin => true,
            :args  => 1,
            :func  => lambda { |nick, arg|
                # TODO add sql to add to oplist
                @@irc.op arg
            },
        },
        "deop" => {
            :admin => true,
            :args  => 1,
            :func  => lambda { |nick, arg|
                # TODO add sql to remove from oplist
                @@irc.deop arg
            },
        },
        "make me a" => {
            :admin => true,
            :args  => 1,
            :func  => lambda { |nick, arg|
                arg = arg.join(" ") if arg.kind_of? Array
                @@irc.speak "Make your own damn #{arg}"
            },
        },
        "#{@@nick} stfu" => {
            :admin => true,
            :args  => 0,
            :func  => lambda { |nick|
                @@irc.speak "fine."
                @@irc.stfu
            },
        },
        "#{@@nick} wtfu" => {
            :admin => true,
            :args  => 0,
            :func  => lambda { |nick|
                @@irc.speak "so now you need me."
                @@irc.wtfu
            },
        },
        "#{@@nick} gtfo" => {
            :admin => true,
            :args  => 0,
            :func  => lambda { |nick|
                @@irc.speak "whateva."
                exit
            },
        },
    }


    def initialize
        @@irc = IRCHole.new(@@server, @@port, @@nick, @@channel, method(:command_handler))
    end

    def start
        @@irc.start
    end

    def command_handler(nick, amzn_user, msg)
        # check if the message is a given command
        @@commands.each do |command, cmd_info|
            @@irc.debug "trying command " + command
            # apply admin prefix
            if cmd_info[:admin]
                command = @@admin_prefix + command
            end

            if msg.start_with? command
                msg = msg[command.length..-1].strip # cut off command from message
                @@irc.debug "^ found this one"
                cmd_info[:func].call(nick, msg)
                break
            end
        end
    end
end
