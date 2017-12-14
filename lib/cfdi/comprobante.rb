module Cfdi
  # La clase principal para crear Comprobantes
  class Comprobante

    # los datos para la cadena original en el órden correcto
    # @private
    @@datosCadena = [:version, :fecha, :tipoDeComprobante, :formaDePago, :condicionesDePago, :subTotal, :descuento, :TipoCambio, :moneda, :total, :metodoDePago, :lugarExpedicion, :NumCtaPago]
    # Todos los datos del comprobante
    # @private
    @@data = @@datosCadena+[:emisor, :receptor, :conceptos, :serie, :folio, :sello, :noCertificado, :certificado, :conceptos, :complemento, :cancelada, :impuestos]
    attr_accessor *@@data

    @addenda = nil

    @@options = {
      :tasa => 0.16,
      :defaults => {
        :moneda => 'MXN',
        :version => '3.3',
        :subTotal => 0.0,
        :conceptos => [],
        :impuestos => [],
        :tipoDeComprobante => 'I'
      }
    }

    # Configurar las opciones default de los comprobantes
    #
    # == Parameters:
    # options::
    #  Las opciones del comprobante: tasa (de impuestos), defaults: un Hash con la moneda (pesos), version (3.2), TipoCambio (1), y tipoDeComprobante (ingreso)
    #
    # @return [Hash]
    #
    def self.configure (options)
      @@options = Comprobante.rmerge @@options, options
      @@options
    end

    # Crear un comprobante nuevo
    #
    # @param  data [Hash] Los datos de un comprobante
    # @option data [String] :version ('3.2') La version del Cfdi
    # @option data [String] :fecha ('') La fecha del Cfdi
    # @option data [String] :tipoDeComprobante ('ingreso') El tipo de Comprobante
    # @option data [String] :formaDePago ('') La forma de pago (pago en una sóla exhibición?)
    # @option data [String] :condicionesDePago ('') Las condiciones de pago (Efectos fiscales al pago?)
    # @option data [String] :TipoCambio (1) El tipo de cambio para la moneda de este Cfdi'
    # @option data [String] :moneda ('pesos') La moneda de pago
    # @option data [String] :metodoDePago ('') El método de pago (depósito bancario? efectivo?)
    # @option data [String] :lugarExpedicion ('') El lugar dónde se expide la factura (Nutopía, México?)
    # @option data [String] :NumCtaPago (nil) El número de cuenta para el pago
    #
    # @param  options [Hash] Las opciones para este comprobante
    # @see [Comprobante@@options] Opciones
    #
    # @return {Cfdi::Comprobante}
    def initialize (data={}, options={})
      #hack porque dup se caga con instance variables
      opts = Marshal::load(Marshal.dump(@@options))
      data = opts[:defaults].merge data
      @opciones = opts.merge options
      data.each do |k,v|
        method = "#{k}="
        next if !self.respond_to? method
        self.send method, v
      end
    end


    def addenda= addenda
      addenda = Addenda.new addenda unless addenda.is_a? Addenda
      @addenda = addenda
    end


    # Regresa el subtotal de este comprobante, tomando el importe de cada concepto
    #
    # @return [Float] El subtotal del comprobante
    def subTotal
      ret = 0
      @conceptos.each do |c|
        ret += c.importe
      end
      ret
    end


    # Regresa el total
    #
    # @return [Float] El subtotal multiplicado por la tasa
    def total
      self.subTotal+(self.subTotal*@opciones[:tasa])
    end


    # Asigna un emisor de tipo {Cfdi::Entidad}
    # @param  emisor [Hash, Cfdi::Entidad] Los datos de un emisor
    #
    # @return [Cfdi::Entidad] Una entidad
    def emisor= emisor
      emisor = Entidad.new emisor unless emisor.is_a? Entidad
      @emisor = emisor;
    end


    # Asigna un receptor
    # @param  receptor [Hash, Cfdi::Entidad] Los datos de un receptor
    #
    # @return [Cfdi::Entidad] Una entidad
    def receptor= receptor
      receptor = Entidad.new receptor unless receptor.is_a? Entidad
      @receptor = receptor;
      receptor
    end

    # Agrega uno o varios conceptos
    # @param  conceptos [Array, Hash, Cfdi::Concepto] Uno o varios conceptos
    #
    # En caso dconceptose darle un Hash o un {Cfdi::Concepto}, agrega este a los conceptos, de otro modo, sobreescribe los conceptos pre-existentes
    #
    # @return [Array] Los conceptos de este comprobante
    def conceptos= datos
      conceptos = []
      if datos.is_a? Array
        conceptos = datos.map! do |concepto|
          concepto = Concepto.new concepto unless concepto.is_a? Concepto
        end
      elsif datos.is_a? Hash
        conceptos << Concepto.new(datos)
      elsif datos.is_a? Concepto
        conceptos << conceptos
      end

      @conceptos = conceptos
      conceptos
    end


    # Asigna un complemento al comprobante
    # @param  complemento [Hash, Cfdi::Complemento] El complemento a agregar
    #
    # @return [Cfdi::Complemento]
    def complemento= complemento
      complemento = Complemento.new complemento unless complemento.is_a? Complemento
      @complemento = complemento
      complemento
    end


    # Asigna una fecha al comprobante
    # @param  fecha [Time, String] La fecha y hora (YYYY-MM-DDTHH:mm:SS) de la emisión
    #
    # @return [String] la fecha en formato '%FT%R:%S'
    def fecha= fecha
      fecha = fecha.strftime('%FT%R:%S') unless fecha.is_a? String
      @fecha = fecha
    end


    # El comprobante como XML
    #
    # @return [String] El comprobante namespaceado en versión 3.2 (porque soy un huevón)
    def to_xml
      ns = {
        'xmlns:Cfdi' => "http://www.sat.gob.mx/cfd/3",
        'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
        # 'xsi:schemaLocation' => "http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv32.xsd",
        'xsi:schemaLocation' => "http://www.sat.gob.mx/cfd/3 http://www.sat.gob.mx/sitio_internet/cfd/3/cfdv33.xsd"
      }

      ns[:Version] = @version
      ns[:Fecha] = @fecha
      ns[:TipoDeComprobante] = @tipoDeComprobante
      ns[:FormaDePago] = @formaDePago if @formaDePago
      ns[:CondicionesDePago] = @condicionesDePago if @condicionesDePago
      ns[:SubTotal] = self.subTotal
      ns[:Descuento] = @descuento if @descuento
      ns[:TipoCambio] = @TipoCambio if @TipoCambio
      ns[:Moneda] = @moneda
      ns[:Total] = self.total
      ns[:MetodoDePago] = @metodoDePago if @metodoDePago
      ns[:LugarExpedicion] = @lugarExpedicion
      ns[:Confirmacion] = @confirmacion if @confirmacion
      ns[:Folio] = @folio if @folio
      ns[:Serie] = @serie if @serie
      ns[:Sello] = @sello if @sello
      ns[:NoCertificado] = @noCertificado if @noCertificado
      ns[:Certificado] = @certificado if @noCertificado

      if (@addenda)
        # Si tenemos addenda, entonces creamos el campo "xmlns:ElNombre" y agregamos sus definiciones al SchemaLocation
        ns["xmlns:#{@addenda.nombre}"] = @addenda.namespace
        ns['xsi:schemaLocation'] += ' '+[@addenda.namespace, @addenda.xsd].join(' ')
      end

      @builder = Nokogiri::XML::Builder.new(:encoding => 'UTF-8') do |xml|
        xml.Comprobante(ns) do
          ins = xml.doc.root.add_namespace_definition('Cfdi', 'http://www.sat.gob.mx/cfd/3')
          xml.doc.root.namespace = ins
          xml.Emisor(@emisor.nsE)
          xml.Receptor(@receptor.nsR)
          xml.Conceptos {
            @conceptos.each do |concepto|
              xml.Concepto(
                :ClaveProdServ => concepto.claveProdServ,
                :Cantidad => concepto.cantidad,
                :ClaveUnidad => concepto.claveUnidad,
                :Descripcion => concepto.descripcion,
                :ValorUnitario => concepto.valorUnitario,
                :Importe => concepto.importe
              ) {
                xml.Impuestos {
                  xml.Traslados {
                    xml.Traslado(
                      :Base => concepto.importe,
                      :Impuesto => "002",
                      :TipoFactor => "Tasa",
                      :TasaOCuota => @opciones[:tasa].to_f,
                      :Importe => concepto.importe * @opciones[:tasa].to_f
                    )
                  }
                }
              }
            end
          }
          xml.Impuestos({:TotalImpuestosTrasladados => self.subTotal*@opciones[:tasa]}) {
            xml.Traslados {
              @impuestos.each do |impuesto|
                xml.Traslado({
                  # :Base => self.subTotal,
                  :Impuesto => impuesto[:impuesto],
                  :TasaOCuota => @opciones[:tasa].to_f,
                  :TipoFactor => "Tasa",
                  :Importe => self.subTotal*@opciones[:tasa]
                })
              end
            }
          }
          # xml.Complemento {

          #   if @complemento
          #     nsTFD = {
          #       'xsi:schemaLocation' => 'http://www.sat.gob.mx/TimbreFiscalDigital http://www.sat.gob.mx/TimbreFiscalDigital/TimbreFiscalDigital.xsd',
          #       'xmlns:tfd' => 'http://www.sat.gob.mx/TimbreFiscalDigital',
          #       'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance'
          #     }
          #     xml['tfd'].TimbreFiscalDigital(@complemento.to_h.merge nsTFD) {
          #     }

          #   end
          # }

          if (@addenda)
            xml.Addenda {
              @addenda.data.each do |k,v|
                if v.is_a? Hash
                  xml[@addenda.nombre].send(k, v)
                elsif v.is_a? Array
                  xml[@addenda.nombre].send(k, v)
                else
                  xml[@addenda.nombre].send(k, v)
                end
              end
            }
          end

        end
      end
      @builder.to_xml
    end


    # Un hash con todos los datos del comprobante, listo para Hash.to_json
    #
    # @return [Hash] El comprobante como Hash
    def to_h
      hash = {}
      @@data.each do |key|
        data = deep_to_h send(key)
        hash[key] = data
      end

      return hash
    end


    # La cadena original del Cfdi
    #
    # @return [String] Separada por pipes, because fuck you that's why
    def cadena_original
      doc = Nokogiri::XML(self.to_xml)
      spec = Gem::Specification.find_by_name("Cfdi")
      # xslt = Nokogiri::XSLT(File.read(spec.gem_dir + "/lib/cadenaoriginal_3_3.xslt"))
      xslt = Nokogiri::XSLT(File.read(File.dirname(__FILE__) + "/cadenaoriginal_3_3.xslt"))

      return xslt.transform(doc)
    end

    # @private
    def self.rmerge defaults, other_hash
      result = defaults.merge(other_hash) do |key, oldval, newval|
        oldval = oldval.to_hash if oldval.respond_to?(:to_hash)
        newval = newval.to_hash if newval.respond_to?(:to_hash)
        oldval.class.to_s == 'Hash' && newval.class.to_s == 'Hash' ? Comprobante.rmerge(oldval, newval) : newval
      end
      result
    end

    private
    def deep_to_h value

      if value.is_a? ElementoComprobante
        original = value.to_h
        value = {}
        original.each do |k,v|
          value[k] = deep_to_h v
        end

      elsif value.is_a?(Array)
        value = value.map do |v|
          deep_to_h v
        end
      end
      value

      #value = value.to_h if value.respond_to? :to_h
      #if value.each do |vi|
      #  value.map do |k,v|
      #    v = deep_to_h v
      #  end
      #end
      value
    end
  end
end