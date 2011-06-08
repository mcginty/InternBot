require 'socket'
require 'uri'
require 'InternDB'
require 'IRCHole'
require 'rubygems'
require 'sqlite3'

class InternBot
    @@irc = nil
    @@admin_prefix = "sudo "

    @@server = "irc.freenode.net"
    @@port = "6667"
    @@nick = "internbot"
    @@channel = "#internbot"

    @@commands = {
        "face" => {
            :admin      => false, # does this require an op to give the command?
            :exact_args => 1,     # an exact arg is an argument without a space
            :excess     => false, # whether other "excess" args are wanted
            :func  => lambda { |nick, arg|
                @@irc.putraw "WHOIS #{arg}"
                whois = @@irc.getraw
                whois = whois.split(" ")[4]
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
            :admin      => false,
            :exact_args => 1,
            :excess     => false,
            :func  => lambda { |nick, arg|
                @@irc.putraw "WHOIS #{arg}"
                whois = @@irc.getraw
                whois = whois.split(" ")[4]
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
            :admin      => true,
            :exact_args => 1,
            :excess     => false,
            :func  => lambda { |nick, arg|
                @@irc.putraw "WHOIS #{arg}"
                whois = @@irc.getraw
                whois = whois.split(" ")[4]
                InternDB.add_op(arg, whois)
                @@irc.op arg
            },
        },
        "deop" => {
            :admin      => true,
            :exact_args => 1,
            :excess     => false,
            :func  => lambda { |nick, arg|
                InternDB.remove_op arg
                @@irc.deop arg
            },
        },
        "make me a" => {
            :admin      => true,
            :exact_args => 0,
            :excess     => true,
            :func  => lambda { |nick, arg|
                arg = arg.join(" ") if arg.kind_of? Array
                if arg.empty?
                    return
                end
                @@irc.speak "Make your own damn #{arg}"
            },
        },
        "#{@@nick} stfu" => {
            :admin      => true,
            :exact_args => 0,
            :excess     => false,
            :func  => lambda { |nick|
                @@irc.speak "fine."
                @@irc.stfu
            },
        },
        "#{@@nick} wtfu" => {
            :admin      => true,
            :exact_args => 0,
            :excess     => false,
            :func  => lambda { |nick|
                @@irc.speak "so now you need me."
                @@irc.wtfu
            },
        },
        "#{@@nick} gtfo" => {
            :admin      => true,
            :exact_args => 0,
            :excess     => false,
            :func  => lambda { |nick|
                @@irc.speak "whateva."
                exit
            },
        },
    }

    class << self

        def start(db)
            InternDB.connect(db)
            @@irc = IRCHole.new(@@server, @@port, @@nick, @@channel, method(:command_handler))
            @@irc.start
        end

        def command_handler(nick, amzn_user, msg)
            # check if the message is a given command
            @@commands.each do |command, cmd_info|
                # apply admin prefix
                if cmd_info[:admin] and InternDB.is_op?(nick, amzn_user)
                    command = @@admin_prefix + command
                else
                    next
                end

                if msg.start_with? command
                    msg = msg[command.length..-1].strip # cut off command from message
                    @@irc.debug "command: "+command

                    # put args in array, and the excess as a string
                    args = msg.split(" ")[0..(cmd_info[:exact_args]-1)]
                    if cmd_info[:excess]
                        args << msg.split(" ")[cmd_info[:exact_args]..-1].join(" ")
                    end
                    cmd_info[:func].call(nick, *args)
                    break
                end
            end
        end
    end
end
