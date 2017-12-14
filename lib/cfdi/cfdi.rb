require 'comun'
require 'addenda'
require 'comprobante'
require 'cancelada'
require 'entidad'
require 'concepto'
require 'complemento'
require 'xml'
require 'certificado'
require 'key'

# Comprobantes fiscales digitales por los internets

require 'time'
require 'base64'
require 'nokogiri'

module Cfdi
  # La versión de este gem
  def self.root
    File.expand_path('../../..',__FILE__)
  end
end
