class Klomp
  VERSION = '1.0.8'

  class Error < StandardError; end

  attr_reader :connections

  def initialize(servers, options = {})
    servers = [servers].flatten
    raise ArgumentError, "no servers given" if servers.empty?
    @connections = servers.map {|s| Connection.new(s, options) }
  end

  def publish(queue, body, headers = {})
    connections_remaining = connections.dup
    begin
      conn = connections_remaining[rand(connections_remaining.size)]
      conn.publish(queue, body, headers)
    rescue
      connections_remaining.delete conn
      retry unless connections_remaining.empty?
      raise
    end
  end


  def subscribe(queue, subscriber = nil, headers = {}, &block)
    connections.map {|conn| conn.subscribe(queue, subscriber, headers, &block) }
  end

  def unsubscribe(queue, headers = {})
    if Array === queue
      raise ArgumentError,
        "wrong size array for #{connections.size} (#{queue.size})" unless connections.size == queue.size
      connections.zip(queue).map {|conn,arg| conn.unsubscribe(arg, headers) rescue nil }
    else
      connections.map {|conn| conn.unsubscribe(queue, headers) rescue nil }
    end
  end

  def connected?
    connections.detect(&:connected?)
  end

  def disconnect
    connections.map {|conn| conn.disconnect }.tap do
      @connections = []
    end
  end
end

require 'klomp/subscription'
require 'klomp/connection'
require 'klomp/sentinel'
require 'klomp/frames'
