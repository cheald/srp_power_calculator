module Plans
  module SRP
    class MPower < Base
      # I _think_ that MPower doesn't assess a separate service charge. I'd like to double check this.
      def fixed_charges
        0
      end

      def rate(date)
        case date.month
        when 1..4, 11..12
          0.0782
        when 5..6, 9..10
          0.1114
        else
          0.1185
        end
      end
    end
  end
end
