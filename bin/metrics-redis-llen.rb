#!/usr/bin/env ruby
#
# Get the length of a list and push it to graphite
#
#
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'sensu-plugin/metric/cli'
require 'redis'

class RedisListLengthMetric < Sensu::Plugin::Metric::CLI::Graphite
  option :socket,
         short: '-s SOCKET',
         long: '--socket SOCKET',
         description: 'Redis socket to connect to (overrides Host and Port)',
         required: false

  option :host,
         short: '-h HOST',
         long: '--host HOST',
         description: 'Redis Host to connect to',
         default: '127.0.0.1'

  option :port,
         short: '-p PORT',
         long: '--port PORT',
         description: 'Redis Port to connect to',
         proc: proc(&:to_i),
         default: 6379

  option :database,
         short: '-n DATABASE',
         long: '--dbnumber DATABASE',
         description: 'Redis database number to connect to',
         proc: proc(&:to_i),
         required: false,
         default: 0

  option :password,
         short: '-P PASSWORD',
         long: '--password PASSWORD',
         description: 'Redis Password to connect with'

  option :scheme,
         description: 'Metric naming scheme, text to prepend to metric',
         short: '-S SCHEME',
         long: '--scheme SCHEME',
         default: "#{Socket.gethostname}.redis"

  option :key,
         short: '-k KEY1,KEY2',
         long: '--key KEY',
         description: 'Comma separated list of keys to check',
         required: true

  option :conn_failure_status,
         long: '--conn-failure-status EXIT_STATUS',
         description: 'Returns the following exit status for Redis connection failures',
         default: 'unknown',
         in: %w(unknown warning critical)

  def run
    redis_keys = config[:key].split(',')
    options = if config[:socket]
                { path: socket }
              else
                { host: config[:host], port: config[:port] }
              end

    options[:db] = config[:database]
    options[:password] = config[:password] if config[:password]
    redis = Redis.new(options)

    redis_keys.each do |key|
      output "#{config[:scheme]}.#{key}.items", redis.llen(key)
    end
    ok
  rescue
    send(config[:conn_failure_status], "Could not connect to Redis server on #{config[:host]}:#{config[:port]}")
  end
end
