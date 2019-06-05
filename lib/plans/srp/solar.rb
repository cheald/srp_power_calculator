module Plans
  module SRP
    class Solar < Plans::SolarBase
      def display_name
        "SRP/E27 (Customer Generation)"
      end

      def notes
        n = "Estimated system cost: #{system_cost}."
        n += " Demand charges are estimated and may be inaccurate." unless @demand_schedule
        n
      end

      def fixed_charges
        32.44
      end

      def demand_usage(date, hour, kwh)
        return 0 if level(date, hour) == 0
        if @demand_schedule
          demand_for_period(date)
        else
          # SRP cares about half-hour demand, but it doesn't particularly define this; I think this means effectively
          # the peak kilowatt-half hour for the month. We'll use 15% over the peak value of any individual hour, to
          # estimate cases where peak draw was high for a period, and was then dropped for the remainder of the hour.
          kwh * 1.15
        end
      end

      # Only accumulate demand charges for on-peak periods
      def add_demand(date, kwh)
        return 0 unless level(date, date.hour) > 0

        if kwh > 20
          p [kwh, date, level(date, date.hour)]
        end

        super
      end

      def demand_cost(demand, date, hour)
        a = nil
        b = nil
        c = nil
        case date.month
        when 1..4, 11..12
          a = 3.49
          b = 5.58
          c = 9.57
        when 5..6, 9..10
          a = 7.89
          b = 14.37
          c = 27.28
        else
          a = 9.43
          b = 17.51
          c = 33.59
        end

        peak_demand = demand_for_period(date) || 0
        return 0 if peak_demand == 0

        if peak_demand > 10
          ((a * 3) + (b * 7) + (c * (peak_demand - 10)))
        elsif peak_demand > 3
          ((a * 3) + (b * (peak_demand - 3)))
        else
          a
        end
      end

      def level(date, hour)
        return 0 if holiday?(date)
        case date.month
        when 1..4, 11..12
          case hour
          when 5...9, 17...21
            1
          else
            0
          end
        else
          case hour
          when 14...20
            1
          else
            0
          end
        end
      end

      def rate(date, hour)
        l = level date, hour
        case date.month
        when 1..4, 11..12
          case l
          when 0
            0.0370
          when 1
            0.0410
          else
            raise "Bad level"
          end
        when 5..6, 9..10
          case l
          when 0
            0.0360
          when 1
            0.0462
          else
            raise "Bad level"
          end
        when 7..8
          case l
          when 0
            0.0412
          when 1
            0.0622
          else
            raise "Bad level"
          end
        else
          raise "Bad level"
        end
      end
    end
  end
end
