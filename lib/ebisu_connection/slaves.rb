module EbisuConnection
  class Slaves
    class Slave
      attr_reader :hostname, :weight

      def initialize(conf, spec)
        case conf
        when String
          @hostname, weight = conf.split(/\s*,\s*/)
          edit_spec = {:host => @hostname}
        when Hash
          conf = symbolize_keys(conf)
          weight = conf.delete(:weight)
          edit_spec = conf
          @hostname = conf[:host]
        else
          raise ArgumentError, "slaves config is invalid"
        end

        @spec = spec.merge(edit_spec)
        @weight = (weight || 1).to_i
      end

      def connection
        @connection ||= ActiveRecord::Base.send("#{@spec["adapter"]}_connection", @spec)
      end

      def disconnect!
        if @connection
          @connection.disconnect!
          @connection = nil
        end
      rescue
      end

      private

      def symbolize_keys(hash)
        symbolize_hash = {}
        hash.each do |k,v|
          symbolize_hash[k.to_sym] = v
        end
        symbolize_hash
      end
    end

    def initialize(slaves_conf, spec)
      weight_list = []
      @slaves = slaves_conf.map do |conf|
        s = Slave.new(conf, spec)
        weight_list << s.weight
        s
      end

      @roulette = []
      gcd = get_gcd(weight_list)
      weight_list.each_with_index do |w, index|
        weight = w / gcd
        @roulette.concat([index] * weight)
      end
    end

    def sample
      @slaves[@roulette.sample]
    end

    def all_disconnect!
      @reserve_release = nil
      @slaves.each {|s| s.disconnect!}
    end

    def reserve_release_connection!
      @reserve_release = true
    end

    def reserved_release?
      !!@reserve_release
    end

    private

    def get_gcd(list)
      list = list.sort.uniq
      n = list.shift
      return n if n == 1 || list.empty?

      while !list.empty?
        m = list.shift
        n = gcd_euclid(m, n)
      end
      n
    end

    def gcd_euclid(m, n)
      m, n = n, m if m < n
      while n != 0
        work = m % n
        m = n
        n = work
      end
      m
    end
  end
end
