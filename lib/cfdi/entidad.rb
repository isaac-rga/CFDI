module Cfdi

  # Una persona fiscal
  #
  # @attr rfc [String] El RFC
  # @attr nombre [String] El nombre o razón social de la entidad
  # @attr domicilioFiscal [Cfdi::Domicilio, Hash] El domicilio de esta entidad
  # @attr regimenFiscal [String] El régimen fiscal, sólo de un emisor
  # @attr expedidoEn [Cfdi::Domicilio, Hash] El domicilio de la sucursal de emisión
  class Entidad < ElementoComprobante
    # @private
    # @cadenaOriginal = [:rfc, :nombre, :domicilioFiscal, :expedidoEn, :regimenFiscal]
    @cadenaOriginal = [:rfc, :nombre, :regimenFiscal, :usoCfdi]
    # @private
    @data = @cadenaOriginal
    # @private
    attr_accessor *@cadenaOriginal

    # @private
    def cadena_original
      expedido = @expedidoEn ? @expedidoEn.cadena_original : nil
      return [
        @rfc,
        @nombre,
        @domicilioFiscal.cadena_original,
        expedido,
        @regimenFiscal
      ].flatten
    end


    # Asigna un domicilioFiscal
    # @param  domicilio [Cfdi::Domicilio, Hash] El domicilio de esta entidad
    #
    # @return [Cfdi::Domicilio] idem
    def domicilioFiscal= domicilio
      domicilio = Domicilio.new domicilio unless domicilio.is_a? Domicilio
      @domicilioFiscal = domicilio
      @domicilioFiscal
    end

    # Designa dónde se expidió el comprobante, sólo para Entidades de tipo "Emisor"
    # @param  domicilio [Cfdi::Domicilio, Hash] El domicilio de expedición de este emisor
    #
    # @return [Cfdi::Domicilio] idem
    def expedidoEn= domicilio
      return if !domicilio
      domicilio = Domicilio.new domicilio unless domicilio.is_a? Domicilio
      @expedidoEn = domicilio
    end

    # @private
    def nsE
      return ({
        :Nombre => @nombre,
        :Rfc => @rfc,
        :RegimenFiscal => @regimenFiscal
      })
    end

    :usoCfdi

    # @private
    def nsR
      return ({
        :Rfc => @rfc,
        :UsoCfdi => @usoCfdi
      })
    end

  end


  # Un domicilio
  #
  # @attr [String] calle La calle
  # @attr [String] noExterior El número exterior
  # @attr [String] noInterior El número interior
  # @attr [String] colonia La colonia
  # @attr [String] localidad La localidad (o ciudad)
  # @attr [String] referencia La referencia: lotería!.
  # @attr [String] municipio El municipio
  # @attr [String] estado El estado
  # @attr [String] pais El país
  # @attr [String] codigoPostal El código postal
  class Domicilio < ElementoComprobante

    @cadenaOriginal = [:calle, :noExterior, :noInterior, :colonia, :localidad, :referencia, :municipio, :estado, :pais, :codigoPostal]
    attr_accessor *@cadenaOriginal

  end

end