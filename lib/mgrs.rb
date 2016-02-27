require "mgrs/version"
require 'openssl'

module MGRS
  LATITUDE_BAND_LETTERS = [
    'C','D','E','F','G','H','J','K','L','M',
    'N','P','Q','R','S','T','U','V','W','X'
  ]

  SQUARE_ID_COLUMN_LETTERS = [
    'A','B','C','D','E','F','G','H','J','K','L','M',
    'N','P','Q','R','S','T','U','V','W','X','Y','Z'
  ]

  SQUARE_ID_ROW_LETTERS = [
    'A','B','C','D','E','F','G','H','J','K',
    'L','M','N','P','Q','R','S','T','U','V'
  ]
  # Your code goes here...
  def self.parse(position)

    unless position.is_a?(String)
      raise ArgumentError.new "Invalid argument type, must be a String"
    end

    unless position.length < 20
      raise ArgumentError.new "Invalid argument format, exceeds max length"
    end

    unless position.length > 3
      raise ArgumentError.new "Invalid argument format, too short"
    end

    if position.include?(' ')
      normalized_position = position.upcase.split(' ').join
    else
      normalized_position = position.upcase
    end

    zone_number     = normalized_position[0..1].to_i.to_s
    latitude_band   = normalized_position[2]

    column_letter   = normalized_position[3]
    row_letter      = normalized_position[4]

    # index where the numerical_location starts
    index           = 5

    if zone_number != normalized_position[0..1]
      row_letter    = column_letter
      column_letter = latitude_band
      latitude_band = normalized_position[1]
      index         = 4
    end

    numerical_location = normalized_position[index..-1]

    unless numerical_location.length % 2 === 0
      raise ArgumentError.new "Invalid numerical location length, unequal lengths"
    end

    length = numerical_location.length / 2

    easting  = numerical_location[0..(length - 1)][0..4]
    northing = numerical_location[length..-1][0..4]

    hash = {
      position: normalized_position,
      gzd: "#{zone_number}#{latitude_band}",
      gsid: "#{column_letter}#{row_letter}",
      easting: "#{easting}",
      northing: "#{northing}"
    }

    hash
  end

  def self.latitude_letter_designator(latitude)
    #This is here as an error flag to show that the Latitude is outside MGRS limits
    letter = 'Z'

    if ((84 >= latitude) and (latitude >= 72))
      letter = 'X'
    elsif ((72 > latitude) and (latitude >= 64))
      letter = 'W'
    elsif ((64 > latitude) and (latitude >= 56))
      letter = 'V'
    elsif ((56 > latitude) and (latitude >= 48))
      letter = 'U'
    elsif((48 > latitude) and (latitude >= 40))
      letter = 'T'
    elsif ((40 > latitude) and (latitude >= 32))
      letter = 'S'
    elsif ((32 > latitude) and (latitude >= 24))
      letter = 'R'
    elsif ((24 > latitude) and (latitude >= 16))
      letter = 'Q'
    elsif ((16 > latitude) and (latitude >= 8))
      letter = 'P'
    elsif((8 > latitude) and (latitude >= 0))
      letter = 'N'
    elsif ((0 > latitude) and (latitude >= -8))
      letter = 'M'
    elsif ((-8 > latitude) and (latitude >= -16))
      letter = 'L'
    elsif ((-16 > latitude) and (latitude >= -24))
      letter = 'K'
    elsif ((-24 > latitude) and (latitude >= -32))
      letter = 'J'
    elsif ((-32 > latitude) and (latitude >= -40))
      letter = 'H'
    elsif ((-40 > latitude) and (latitude >= -48))
      letter = 'G'
    elsif ((-48 > latitude) and (latitude >= -56))
      letter = 'F'
    elsif ((-56 > latitude) and (latitude >= -64))
      letter = 'E'
    elsif ((-64 > latitude) and (latitude >= -72))
      letter = 'D'
    elsif ((-72 > latitude) and (latitude >= -80))
      letter = 'C'
    end

    return letter
  end
end

require "mgrs/utmcs/grid_cell"
require "mgrs/grid_cell"
