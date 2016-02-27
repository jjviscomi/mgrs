module MGRS
  module UTMCS
    def self.parse(position)
      unless position.is_a?(String)
        raise ArgumentError.new "Invalid argument type, must be a String"
      end

      unless position.length < 20
        raise ArgumentError.new "Invalid argument format, exceeds max length"
      end

      unless position.length > 6
        raise ArgumentError.new "Invalid argument format, too short"
      end

      if position.include?(' ')
        normalized_positions = position.upcase.split(' ')
      else
        raise ArgumentError.new "Invalid argument format, needs three parts"
      end

      zone_number     = normalized_positions[0].to_i.to_s
      latitude_band   = normalized_positions[0][-1].to_s

      easting         = normalized_positions[1]
      northing        = normalized_positions[2]

      hash = {
        position: normalized_positions.join(' '),
        zone: "#{zone_number}#{latitude_band}",
        easting: "#{easting}",
        northing: "#{northing}"
      }

      hash
    end

    def self.latitude_letter_designator(latitude)
      MGRS.latitude_letter_designator(latitude)
    end

    class GridCell
      attr_reader   :position, :zone, :easting, :northing,
                    :latitude, :longitude

      def initialize(position: nil, latitude: nil, longitude: nil)
        configure_params(position: position,
                         latitude: latitude,
                         longitude: longitude)
      end

      def load(hash)
        old_hash = dump
        begin
          restore(hash)
        rescue Exception
          restore(old_hash)
        end
        return self
      end

      def dump()
        to_h
      end

      def to_s
        "#{@zone} #{@easting} #{@northing}"
      end

      def to_h
        {
          position: @position,
          zone: @zone,
          easting: @easting, northing: @northing
        }
      end

      def position=(newPosition)
        old_hash = to_h

        begin
          setup_instance_variables position: newPosition
        rescue Exception
          restore(old_hash)
        end

        self
      end

      def latitude=(newLatitude)
        old_hash = dump

        begin
          if not longitude.nil?
            utm_dump = lat_long_to_utm latitude: newLatitude, longitude: longitude
            setup_instance_variables position: utm_dump[:position]
          end
        rescue Exception
          restore(old_hash)
        end

        self
      end

      def longitude=(newLongitude)
        old_hash = to_h

        begin
          if not latitude.nil?
            utm_dump = lat_long_to_utm latitude: latitude, longitude: newLongitude
            setup_instance_variables position: utm_dump[:position]
          end
        rescue Exception
          restore(old_hash)
        end

        self
      end

      def hemisphere
        band = zone[-1]

        unless not band.nil?
          return nil
        end

        if band >= 'N'
          return 'N'
        end

        return 'S'
      end

      private

        def configure_params(position:, latitude:, longitude:)

          if position.nil? and latitude.nil? and longitude.nil?
            @position = nil

            @latitude   = nil
            @longitude  = nil

            #UTMCS POSITION PARTS
            @zone       = nil
            @easting    = nil
            @northing   = nil

          elsif not position.nil? and latitude.nil? and longitude.nil?
            setup_instance_variables position: position
          elsif position.nil? and not latitude.nil? and not longitude.nil?
            utm_dump = lat_long_to_utm latitude: latitude, longitude: longitude
            setup_instance_variables position: utm_dump[:position]
          end
          self
        end

        def setup_instance_variables(position:)

          hash = UTMCS.parse position

          unless valid_zone_number?(hash[:zone].to_i)
            raise ArgumentError.new "Invalid zone number (#{hash[:zone].to_i})"
          end

          unless valid_latitude_band?(hash[:zone][-1])
            raise ArgumentError.new "Invalid latitude band (#{hash[:gzd][hash[:gzd].to_i.to_s.length]})"
          end

          restore hash
        end

        def restore(hash)
          @zone       = hash[:zone]
          @easting    = hash[:easting]
          @northing   = hash[:northing]

          lat_long = to_lat_long
          #
          @latitude   = lat_long[:latitude]
          @longitude  = lat_long[:longitude]

          @position = hash[:position]

          self
        end

        def valid_zone_number?(zone_number)
          zone_number > 0 and zone_number < 61
        end

        def valid_latitude_band?(latitude_band)
          MGRS::LATITUDE_BAND_LETTERS.include?(latitude_band)
        end

        def to_lat_long
          #{position: position, zone: zone, easting: utm_easting, northing: utm_northing}

          k0 = 0.9996
          a = 6378137.0 #ellip.radius
          eccSquared = 0.00669438 #ellip.eccsq
          # e1 = (1 - Math.sqrt(1 - eccSquared)) / (1 + Math.sqrt(1 - eccSquared))
          e1 = 0.0016792203888649744

          x = easting.to_f - 500000.0
          y = northing.to_f

          y = y - 10000000.0 if zone[-1] < 'N'

          longOrigin = (zone.to_f - 1.0) * 6.0 - 180.0 + 3.0
          # eccPrimeSquared = (eccSquared) / (1 - eccSquared)
          eccPrimeSquared = 0.006739496752268451

          _M = y / k0
          # mu = _M / (a * (1 - eccSquared / 4 - 3 * eccSquared * eccSquared / 64 - 5 * eccSquared * eccSquared * eccSquared / 256))
          mu = _M / 6367449.145945056

          # phi1Rad = mu + (3 * e1 / 2 - 27 * e1 * e1 * e1 / 32) * Math.sin(2 * mu) + (21 * e1 * e1 / 16 - 55 * e1 * e1 * e1 * e1 / 32) * Math.sin(4 * mu) + (151 * e1 * e1 * e1 / 96) * Math.sin(6 * mu)
          phi1Rad = mu + 0.002518826588112575 * Math.sin(2.0 * mu) + 3.7009490465577744e-06 * Math.sin(4.0 * mu) + 7.447813800519332e-09 * Math.sin(6.0 * mu)

          _N1 = a / Math.sqrt(1 - eccSquared * Math.sin(phi1Rad) * Math.sin(phi1Rad))
          _T1 = Math.tan(phi1Rad) * Math.tan(phi1Rad)
          _C1 = eccPrimeSquared * Math.cos(phi1Rad) * Math.cos(phi1Rad)
          _R1 = a * (1.0 - eccSquared) / ((1.0 - eccSquared * Math.sin(phi1Rad) * Math.sin(phi1Rad)) ** 1.5)
          _D  = x / (_N1 * k0)

          lat = phi1Rad - (_N1 * Math.tan(phi1Rad) / _R1) * (_D * _D / 2.0 - (5.0 + 3.0 * _T1 + 10.0 * _C1 - 4.0 * _C1 * _C1 - 9.0 * eccPrimeSquared) * _D * _D * _D * _D / 24.0 + (61.0 + 90.0 * _T1 + 298.0 * _C1 + 45.0 * _T1 * _T1 - 252.0 * eccPrimeSquared - 3.0 * _C1 * _C1) * _D * _D * _D * _D * _D * _D / 720.0)
          lat = to_degrees(lat)

          lon = (_D - (1.0 + 2.0 * _T1 + _C1) * _D * _D * _D / 6.0 + (5.0 - 2.0 * _C1 + 28.0 * _T1 - 3.0 * _C1 * _C1 + 8.0 * eccPrimeSquared + 24.0 * _T1 * _T1) * _D * _D * _D * _D * _D / 120.0) / Math.cos(phi1Rad)
          lon = longOrigin + to_degrees(lon)

          # if (accuracy)
          #   topRight = self.utmToLatLong(northing: (northing + accuracy), easting: (easting + accuracy), zoneLetter: zoneLetter, zoneNumber: zoneNumber)
          #   result = { bbox: { top: topRight[:latitude], right: topRight[:longitude], bottom: lat, left: lon }, latitude: lat, longitude: lon }
          # else
          #   result = { latitude: lat, longitude: lon }
          # end

          # return result
          { latitude: lat, longitude: lon }
        end

        def lat_long_to_utm(latitude:, longitude:)
          a               = 6378137.0 #ellip.radius
          eccSquared      = 0.00669438 #ellip.eccsq;
          k0              = 0.9996

          latRad  = to_radians(latitude)
          longRad = to_radians(longitude)
          mtlatRad = Math.tan(latRad)
          mslatRad = Math.sin(latRad)
          mclatRad = Math.cos(latRad)

          zone_number = (((longitude + 180) / 6.0).to_i + 1.0).to_i

          zone_number = 60 if longitude == 180

          # Special zone for Norway
          zone_number = 32 if ((latitude >= 56.0) and (latitude < 64.0) and (longitude >= 3.0) and (longitude < 12.0))

          # Special zone for Svalbard
          if (latitude >= 72.0 and latitude < 84.0)
            if (longitude >= 0.0 and longitude < 9.0)
              zone_number = 31
            elsif (longitude >= 9.0 and longitude < 21.0)
              zone_number = 33
            elsif (longitude >= 21.0 and longitude < 33.0)
              zone_number = 35
            elsif (longitude >= 37.0 and longitude < 42.0)
              zone_number = 37
            end
          end

          longOrigin = (zone_number - 1.0) * 6.0 - 180.0 + 3.0 #+3 puts origin
          longOriginRad = to_radians(longOrigin)

          eccPrimeSquared = 0.006739496752268451

          _N = a / Math.sqrt(1.0 - eccSquared * mslatRad * mslatRad)
          _T = mtlatRad * mtlatRad
          _C = eccPrimeSquared * mclatRad * mclatRad
          _A = mclatRad * (longRad - longOriginRad)

          # _M = a * ((1 - eccSquared / 4 - 3 * eccSquared * eccSquared / 64 - 5 * eccSquared * eccSquared * eccSquared / 256) * latRad - (3 * eccSquared / 8 + 3 * eccSquared * eccSquared / 32 + 45 * eccSquared * eccSquared * eccSquared / 1024) * Math.sin(2 * latRad) + (15 * eccSquared * eccSquared / 256 + 45 * eccSquared * eccSquared * eccSquared / 1024) * Math.sin(4 * latRad) - (35 * eccSquared * eccSquared * eccSquared / 3072) * Math.sin(6 * latRad))
          _M = a * (0.9983242984503243 * latRad - 0.002514607064228144 * Math.sin(2.0 * latRad) + 2.639046602129982e-06 * Math.sin(4.0 * latRad) - 3.418046101696858e-09 * Math.sin(6.0 * latRad))

          _UTMEasting = (k0 * _N * (_A + (1.0 - _T + _C) * _A * _A * _A / 6.0 + (5.0 - 18.0 * _T + _T * _T + 72.0 * _C - 58.0 * eccPrimeSquared) * _A * _A * _A * _A * _A / 120.0) + 500000.0)
          _UTMNorthing = (k0 * (_M + _N * mtlatRad * (_A * _A / 2.0 + (5.0 - _T + 9.0 * _C + 4.0 * _C * _C) * _A * _A * _A * _A / 24.0 + (61.0 - 58.0 * _T + _T * _T + 600.0 * _C - 330.0 * eccPrimeSquared) * _A * _A * _A * _A * _A * _A / 720.0)))

          _UTMNorthing = _UTMNorthing + 10000000.0 if latitude < 0.0

          #{easting: utm_easting, northing: utm_northing, zone_number: self.zone_number, latitude_band: self.latitude_band, accuracy: accuracy_bonus}

          return { position: "#{zone_number}#{MGRS::UTMCS.latitude_letter_designator(latitude)} #{_UTMEasting.to_i} #{_UTMNorthing.to_i}", zone: "#{zone_number}#{MGRS::UTMCS.latitude_letter_designator(latitude)}", easting: _UTMEasting.to_i.to_s, northing: _UTMNorthing.to_i.to_s }
        end

        def to_radians(degrees)
          degrees * (Math::PI / 180.0)
        end

        def to_degrees(radians)
          180.0 * (radians / Math::PI)
        end

    end
  end
end
