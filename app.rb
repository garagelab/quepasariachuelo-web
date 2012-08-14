# encoding: UTF-8

$LOAD_PATH.unshift(File.expand_path("vendor/ft-0.0.3/lib", File.dirname(__FILE__)))

require "sinatra/base"
require "sequel"
require "json"

Tilt.register 'md', Tilt::RDiscountTemplate

DB = Sequel.connect("fusiontables:///")

FusionTables::Connection::URL = URI.parse("http://tables.googlelabs.com/api/query")

TABLES = {
  #:industrias       => 1731573,
  :industrias       => 4884840,
  :basurales        => 1413418,
  :asentamientos    => 1874853,
  :relocalizaciones => 1809291,
  :reportes         => 1875969,
}

Industrias = DB[TABLES[:industrias]]
Basurales = DB[TABLES[:basurales]]
Asentamientos = DB[TABLES[:asentamientos]]
Reportes = DB[TABLES[:reportes]]
Relocalizaciones = DB[TABLES[:relocalizaciones]]

class NilClass
  def empty?; true; end
end

class QPR < Sinatra::Base
  helpers do
    def root(path)
      File.expand_path(path, File.dirname(__FILE__))
    end

    include Rack::Utils
    alias_method :h, :escape_html

    def join_cols(row, name)
      row.keys.grep(/^#{name}_\d+$/).map do |key|
        row[key] unless row[key].empty?
      end.compact.join("<br>\n")
    end

    def yesno(value)
      if value == "1"
        "Sí"
      else
        "No"
      end
    end
  end

  set :app_file, __FILE__

  WWW = /^(https?:\/\/)www\./
  COM = /^(https?:\/\/)(.+?)\.com\.ar/

  before do
    if request.url =~ WWW
      redirect(request.url.sub(WWW, '\1'), 301)
    end

    if request.url =~ COM
      redirect(request.url.sub(COM, '\1\2.org.ar'), 301)
    end
  end

  get "/" do
    @rubros = File.read(root("data/rubros")).split("\n") + [nil]
    @clasificaciones = [
      "Consolidado",
      "No consolidado",
      "Dinámico",
      "No consolidado con asentamiento",
      "Consolidado con asentamiento"
    ]

    erb(:"index")
  end

  get "/contenido/:page" do |page|
    erb(:"contenido/#{page}")
  end

  get "/preguntas-frecuentes" do
    @sections = {}

    %w(semaforo-industrias).each do |section|
      @sections[section] = render(:md, :"faq/#{section}", :layout => false)
    end

    erb(:"faq", :layout => true)
  end

  get "/industrias/:cuit" do |cuit|
    @industria = Industrias.where(:cuit => cuit).first
    erb(:"industria")
  end

  get "/basurales/:id" do |id|
    @basural = Basurales.where(:id => id).first
    erb(:"basural")
  end

  get "/asentamientos/:id" do |id|
    @asentamiento = Asentamientos.where(:id => id).first
    @relocalizaciones = Relocalizaciones.where(:id => id).all
    erb(:"asentamiento")
  end

  get "/industrias-semaforo.js" do
    rows = Industrias.select(:semaforo_riesgo, :semaforo_legal, :razon_social).all.map do |hash|
      hash.values
    end

    response["Cache-Control"] = "public, max-age=86400"
    %Q{QPR.industrias = {semaforo: #{rows.to_json}};}
  end
end
