require 'socket'
require 'uri'
require 'sqlite3'
require 'IRCHole'
$server = "irc.amazon.com"
$port = "6667"
$nick = "internbot"
$channel = "#intern"
$stfu = FALSE

def message(msg)
    if not $stfu
        $s.puts "PRIVMSG #{$channel} :"+2.chr+"#{msg}"
    end
end

def command_parse(nick, amzn_user, chanmsg)
    #puts "chanmsg parsed from #{nick}@#{amzn_user}"

    # LOOKUP COMMANDS
    if chanmsg[0] == "face" or chanmsg[0] == "whois" and chanmsg.length == 2
        $s.puts "WHOIS #{chanmsg[1]}"
        whois = $s.gets
        whois = whois.split(" ")[4]
        if chanmsg[0] == "face"
            user = chanmsg[1].strip
            if user == nick
                message "Don't fucking ask that, you heartless bastard."
                return
            end
            if whois != ":No"
                message "#{chanmsg[1]}'s face: https://internal.amazon.com/phone/phone-image.cgi?uid=#{whois}"
            else
                message "This IRC user is faceless. Find nearest shelter."
            end
            if chanmsg[1] == "ckenna"
                message ";)"
            end
        elsif chanmsg[0] == "whois"
            user = chanmsg[1].strip
            if whois != ":No"
                message "#{chanmsg[1]}'s lookup: https://contactstool.amazon.com/ac/can/people/find/#{whois}"
            else
                message "This IRC user doesn't have valid WHOIS information."
            end
        end

    # ADMIN COMMANDS
    elsif chanmsg[0] == "sudo"
        if $oplist.index("#{nick}!#{amzn_user}") != nil
            chanmsg = chanmsg[1..-1]
            if chanmsg.join(" ") == "op me"
                $s.puts "MODE #{$channel} +o #{nick}"
            elsif chanmsg[0..2].join(" ") == "make me a"
                message "Make your own damn #{chanmsg[3]}"
            elsif chanmsg[0] == "op" and chanmsg.length == 2
                $s.puts "WHOIS #{chanmsg[1]}"
                whois = $s.gets
                whois = whois.split(" ")[4]
                $oplist << "#{chanmsg[1]}!#{whois}"
                $s.puts "MODE #{$channel} +o #{chanmsg[1]}"
                message "#{chanmsg[1]} honorably promoted to oplist."
            elsif chanmsg[0] == "deop" and chanmsg.length == 2
                $oplist.each_index { |i|
                    if $oplist[i].index(chanmsg[1]) != nil
                        $oplist.delete_at(i)
                    end
                }
                $s.puts "MODE #{$channel} -o #{chanmsg[1]}"
                message "#{chanmsg[1]} baleeted from oplist."
            elsif chanmsg[0] == $nick and chanmsg[1] == "gtfo"
                message "whateva"
                exit(0)
            elsif chanmsg[0] == $nick and chanmsg[1] == "stfu"
                message "fine."
                $stfu = TRUE
            elsif chanmsg[0] == $nick and chanmsg[1] == "wtfu"
                $stfu = FALSE
                message "so now you need me."
            elsif chanmsg[0] == "su"
                message "root@jakemc.desktop.amazon.com ~ $"
            end
        else
            bros = ['J.R. Bro-ppenheimer', 'Bromethius', 'brah', 'poopybutt']
            message "You're not on the list, #{bros.choice}."
        end
    end
end

# ACTUAL CODE START

$s = TCPSocket.open($server, $port)
$s.puts "USER internbot 0 * InternBot"
$s.puts "NICK #{$nick}"
$s.puts "JOIN #{$channel}"

until $s.eof? do
    msg = $s.gets
    # stay-alive
    if msg.start_with?("PING")
        pongback = "PONG " + msg.split(":")[1]
        $s.puts pongback
        puts pongback
    # auto-op the oplisted members
    elsif msg.index("JOIN :#{$channel}")
        msg_pieces = msg.split(':')
        user_info = msg_pieces[1].split('@')[0]
        if $oplist.index(user_info) != nil
            $s.puts "MODE #{$channel} +o #{user_info.split("!")[0]}"
        end
    # command parsing
    elsif msg.index("PRIVMSG #{$channel} :")
        msg_pieces = msg.split(':')
        user_info = msg_pieces[1].split('@')[0]
        user_info = user_info.split('!')
        command_parse(user_info[0], user_info[1], msg_pieces[2..-1].join(":").split(" "))
    end
end
