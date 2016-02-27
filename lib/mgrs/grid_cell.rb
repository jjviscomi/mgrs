module MGRS
  class GridCell

    attr_accessor :utmcs_grid_cell

    attr_reader   :position, :gzd, :gsid,
                  :easting, :northing

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

    def zone_number

      unless not @gzd.nil?
        return nil
      end


      @gzd[0..-2].to_i
    end

    def latitude_band
      unless not @gzd.nil?
        return nil
      end

      @gzd[-1]
    end

    def square_identification
      @gsid
    end

    def numerical_location
      "#{@easting}#{@northing}"
    end

    def hemisphere
      band = latitude_band

      unless not band.nil?
        return nil
      end

      if band >= 'N'
        return 'N'
      end

      return 'S'
    end

    def to_s
      "#{@gzd}#{@gsid} #{@easting} #{@northing}"
    end

    def to_h
      {
        position: @position,
        gzd: @gzd, gsid: @gsid,
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
        if self.utmcs_grid_cell.nil?
          self.utmcs_grid_cell = to_utm
        end
        self.utmcs_grid_cell.latitude = newLatitude

        setup_instance_variables position: utm_to_mgrs_position(self.utmcs_grid_cell)

      rescue Exception
        restore(old_hash)
      end

      self
    end

    def latitude
      utmcs_latitude
    end

    def longitude=(newLongitude)
      old_hash = to_h

      begin
        if self.utmcs_grid_cell.nil?
          self.utmcs_grid_cell = to_utm
        end
        self.utmcs_grid_cell.longitude = newLongitude

        setup_instance_variables position: utm_to_mgrs_position(self.utmcs_grid_cell)

      rescue Exception
        restore(old_hash)
      end

      self
    end

    def longitude
      utmcs_longitude
    end

    private

      def configure_params(position:, latitude:, longitude:)

        if position.nil? and latitude.nil? and longitude.nil?
          @position = nil

          #MGRS COORDINATE PARTS
          @gzd        = nil
          @gsid       = nil
          @easting    = nil
          @northing   = nil

          self.utmcs_grid_cell = MGRS::UTMCS.GridCell.new
        elsif not position.nil? and latitude.nil? and longitude.nil?
          setup_instance_variables position: position
        elsif position.nil? and not latitude.nil? and not longitude.nil?
          self.utmcs_grid_cell = MGRS::UTMCS.GridCell.new latitude: latitude, longitude: longitude
          setup_instance_variables position: utm_to_mgrs_position(self.utmcs_grid_cell)
        end
        self
      end

      def setup_instance_variables(position:)

        hash = MGRS.parse position

        unless valid_zone_number?(hash[:gzd].to_i)
          raise ArgumentError.new "Invalid grid-zone number (#{hash[:gzd].to_i})"
        end

        unless valid_latitude_band?(hash[:gzd][hash[:gzd].to_i.to_s.length])
          raise ArgumentError.new "Invalid grid-zone latitude band (#{hash[:gzd][hash[:gzd].to_i.to_s.length]})"
        end

        unless valid_column_letter?(hash[:gsid][0])
          raise ArgumentError.new "Invalid column letter for square id"
        end

        unless valid_row_letter?(hash[:gsid][1])
          raise ArgumentError.new "Invalid row letter for square id"
        end

        restore hash
      end

      def restore(hash)
        @gzd        = hash[:gzd]
        @gsid       = hash[:gsid]
        @easting    = hash[:easting]
        @northing   = hash[:northing]

        if self.utmcs_grid_cell.nil?
          self.utmcs_grid_cell = to_utm
        else
          self.utmcs_grid_cell.position = to_utm.position
        end

        unless valid_mgrs?(self.utmcs_grid_cell)
          raise ArgumentError.new "Invalid MRGS position"
        end

        @position = utm_to_mgrs_position self.utmcs_grid_cell

        self
      end

      def valid_zone_number?(zone_number)
        zone_number > 0 and zone_number < 61
      end

      def valid_latitude_band?(latitude_band)
        MGRS::LATITUDE_BAND_LETTERS.include?(latitude_band)
      end

      def valid_column_letter?(column_letter)
        MGRS::SQUARE_ID_COLUMN_LETTERS.include?(column_letter)
      end

      def valid_row_letter?(row_letter)
        MGRS::SQUARE_ID_ROW_LETTERS.include?(row_letter)
      end

      def valid_mgrs?(utmcs_grid_cell)

        unless not utmcs_grid_cell.nil? and self.zone_number.to_s == utmcs_grid_cell.zone.to_i.to_s
          return false
        end

        unless self.latitude_band.to_s == utmcs_grid_cell.zone[-1].to_s
          return false
        end

        unless @gsid.to_s == get100kID(easting: utmcs_grid_cell.easting.to_i, northing: utmcs_grid_cell.northing.to_i, zone_number: utmcs_grid_cell.zone.to_i).to_s
          return false
        end

        seasting  = "#{utmcs_grid_cell.easting}"[1..-1]
        snorthing = "#{utmcs_grid_cell.northing}"[2..-1]

        unless @easting.to_s == seasting.to_s
          return false
        end

        unless @northing.to_s == snorthing.to_s
          return false
        end

        return true
      end

      def get100kID(easting:, northing:, zone_number:)
        setParm   = zone_number_100k_zone_set(zone_number)
        setColumn = (easting / 100000).to_i
        setRow    = (northing / 100000).to_i % 20
        return getLetter100kID(setColumn, setRow, setParm)
      end

      # Get the two-letter MGRS 100k designator given information translated from the UTM northing, easting and zone number.
      def getLetter100kID(column, row, parm)
        index = parm - 1
        colOrigin = ['A','J','S','A','J','S'][index].ord
        rowOrigin = ['A','F','A','F','A','F'][index].ord

        colInt = colOrigin + column - 1
        rowInt = rowOrigin + row
        rollover = false

        _A = 65
        _I = 73
        _O = 79
        _V = 86
        _Z = 90

        if (colInt > _Z)
          colInt = colInt - _Z + _A - 1
          rollover = true
        end

        if (colInt == _I or (colOrigin < _I and colInt > _I) or ((colInt > _I or colOrigin < _I) and rollover))
          colInt = colInt + 1
        end

        if (colInt == _O or (colOrigin < _O and colInt > _O) or ((colInt > _O or colOrigin < _O) and rollover))
          colInt = colInt + 1

          if (colInt == _I)
            colInt = colInt + 1
          end
        end

        if (colInt > _Z)
          colInt = colInt - _Z + _A - 1
        end

        if (rowInt > _V)
          rowInt = rowInt - _V + _A - 1
          rollover = true
        else
          rollover = false
        end

        if (((rowInt == _I) or ((rowOrigin < _I) and (rowInt > _I))) or (((rowInt > _I) or (rowOrigin < _I)) and rollover))
          rowInt = rowInt + 1
        end

        if (((rowInt == _O) or ((rowOrigin < _O) and (rowInt > _O))) or (((rowInt > _O) or (rowOrigin < _O)) and rollover))
          rowInt = rowInt + 1

          if (rowInt == _I)
            rowInt = rowInt + 1
          end
        end

        if (rowInt > _V)
          rowInt = rowInt - _V + _A - 1
        end

        return "#{colInt.chr}#{rowInt.chr}"
      end

      def to_utm
        zone_set = zone_number_100k_zone_set(self.zone_number)

        unless not zone_set.nil?
          return nil
        end

        easting_100k  = utm_100k_easting(@gsid[0], zone_set)
        northing_100k = utm_100k_northing(@gsid[1], zone_set)

        loop do
          break if northing_100k >= utm_min_northing(self.latitude_band)
          northing_100k = northing_100k + 2000000.0
        end

        location_length = @easting.length

        utm_easting   = @easting.to_i + easting_100k.to_i
        utm_northing  = @northing.to_i + northing_100k.to_i

        if location_length > 0
          accuracy_bonus = 100000.0 / (10 ** location_length)

          utm_easting   = (@easting.to_f * accuracy_bonus).to_i + easting_100k.to_i
          utm_northing  = (@northing.to_f * accuracy_bonus).to_i + northing_100k.to_i
        end

        MGRS::UTMCS::GridCell.new position: "#{self.zone_number}#{self.latitude_band} #{utm_easting} #{utm_northing}"
      end

      def utmcs_latitude
        if self.utmcs_grid_cell.nil?
          self.utmcs_grid_cell = to_utm
        end

        self.utmcs_grid_cell.latitude
      end

      def utmcs_longitude
        if self.utmcs_grid_cell.nil?
          self.utmcs_grid_cell = to_utm
        end

        self.utmcs_grid_cell.longitude
      end

      def zone_number_100k_zone_set(zone_number)

        unless not zone_number.nil?
          return nil
        end

        zone_set = zone_number % 6 #self.NUM_100K_SETS
        zone_set = 6 if zone_set == 0
        return zone_set
      end

      def utm_100k_easting(mgrs_easting, zone_set)
        curCol = ['A','J','S','A','J','S'][zone_set - 1].ord
        utm_easting_value = 100000.0

        loop do
          break if curCol == mgrs_easting[0].ord
          curCol = curCol + 1
          if (curCol == 73)
            urCol = curCol + 1
          end
          if (curCol == 79)
            urCol = curCol + 1
          end
          if (curCol > 90)
            curCol = 65
          end
          utm_easting_value = utm_easting_value + 100000
        end

        return utm_easting_value
      end

      def utm_100k_northing(mgrs_northing, zone_set)
        curRow = ['A','F','A','F','A','F'][zone_set - 1].ord
        utm_northing_value = 0.0

        loop do
          break if curRow == mgrs_northing[0].ord
          curRow = curRow + 1
          if (curRow == 73)
            curRow = curRow + 1
          end
          if (curRow == 79)
            curRow = curRow + 1
          end

          if (curRow > 86)
            curRow = 65
          end
          utm_northing_value = utm_northing_value + 100000.0
        end

        return utm_northing_value
      end

      def utm_min_northing(latitude_band)
        case latitude_band
        when 'C'
          northing = 1100000.0
        when 'D'
          northing = 2000000.0
        when 'E'
          northing = 2800000.0
        when 'F'
          northing = 3700000.0
        when 'G'
          northing = 4600000.0
        when 'H'
          northing = 5500000.0
        when 'J'
          northing = 6400000.0
        when 'K'
          northing = 7300000.0
        when 'L'
          northing = 8200000.0
        when 'M'
          northing = 9100000.0
        when 'N'
          northing = 0.0
        when 'P'
          northing = 800000.0
        when 'Q'
          northing = 1700000.0
        when 'R'
          northing = 2600000.0
        when 'S'
          northing = 3500000.0
        when 'T'
          northing = 4400000.0
        when 'U'
          northing = 5300000.0
        when 'V'
          northing = 6200000.0
        when 'W'
          northing = 7000000.0
        when 'X'
          northing = 7900000.0
        else
          northing = nil
        end

        return northing
      end

      def utm_to_mgrs_position(utmcs_grid_cell)
        "#{utmcs_grid_cell.zone}#{get100kID(easting: utmcs_grid_cell.easting.to_i, northing: utmcs_grid_cell.northing.to_i, zone_number: utmcs_grid_cell.zone.to_i).to_s}#{utmcs_grid_cell.easting[1..-1]}#{utmcs_grid_cell.northing[2..-1]}"
      end

      def to_radians(degrees)
        degrees * (Math::PI / 180.0)
      end

      def to_degrees(radians)
        180.0 * (radians / Math::PI)
      end

  end
end
