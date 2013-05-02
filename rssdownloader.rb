#!/usr/bin/ruby
=begin

== DESCRIPTION 

Download all item.enclosure.url from a single file containing an rss feed

== DEPENDENCIES

  libruby1.8
  rss (http://raa.ruby-lang.org/project/rss/)
  wget

== CHANGES

created from rssdl in 2010

=end

require "optparse"
require "observer"
require "rss/1.0"
require "rss/2.0"

$wgetcmd = '/usr/bin/wget'
OPTIONS = {
  :verbose => false,
  :testonly => false,
  :targetdir => '.',
}
ARGV.options { |opt|
  opt.on('-d', '--dir=dir', 'output dir') { |v| OPTIONS[:targetdir] = v }
  opt.on('-v', '--verbose', 'verbose output') { |v| OPTIONS[:verbose] = true }
  opt.on('-t', '--testonly', 'testonly, do not download') { |v| OPTIONS[:testonly] = true }
  opt.parse!
} or exit(1)
(print ARGV.options; exit) unless ARGV[0]

module Utils
  class Debug
    # log to array of filehandles (stdout/logfile)
    def initialize(fhs=[$stderr])
      @out = fhs
    end
    # print always
    def print(*msg)
      @out.each { |o| o.puts(msg.join(' ')) }
    end
    # print if verbose
    def note(*msg)
      print(msg) if $verbose
    end
    # print unless quiet
    def log(*msg)
      print(msg) unless $quiet
    end
    # format
    def printf(*msg)
      @out.each { |o| o.printf(*msg) }
    end
    def logf(*msg) 
      printf(*msg) unless $quiet
    end
    # print backtrace
    def error(error,*msg)
      @out.each { |o| 
        o.puts(msg.join(' ')) unless msg.empty?
        o.puts("  "+error.to_s)
        error.backtrace.each { |b| o.puts("\t"+b.to_s) }
      }
    end
  end

  module WGet
    def wget(url,filename=nil)
      if filename.nil?
        # return data
        return `#{$wgetcmd} --quiet #{url} -O -`
      else
        # return cmd status
        return system($wgetcmd,url,'-O',filename)
      end
    end
  end
end

class Downloader
  include Observable
  include Utils::WGet
  def initialize(dir)
    @dir = dir
  end
  def update(url)
    a = url.split('/')
    filename = a[-1]
    $debug.log("### downloading file #{filename}") if OPTIONS[:verbose]
    res = wget(url,"#{@dir}/#{filename}") unless OPTIONS[:testonly]
  end
end

class RSSParser
  include Observable
  def initialize(downloader, feed)
    @downloader = downloader
    @feed = File.open(feed)
  end

  def check_feed
    begin
      rss = RSS::Parser.parse(@feed)
      rss.items.each { |item|
        #puts item.link if item.link
        next unless item.enclosure
        changed
        notify_observers(item.enclosure.url)
      } 
    rescue
      $debug.error($!,'### parsing rss:')
    end
  end

end

class Action
  def initialize(feed)
    @downloader = Downloader.new(OPTIONS[:targetdir])
    @fetcher = RSSParser.new( @downloader, feed)
    @fetcher.add_observer(@downloader)
  end

  def start
    @fetcher.check_feed
  end

end

$debug = Utils::Debug.new
$action = Action.new(ARGV[0])
$action.start


