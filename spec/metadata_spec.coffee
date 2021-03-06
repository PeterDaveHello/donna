fs = require 'fs'
path = require 'path'

{inspect} = require 'util'
walkdir = require 'walkdir'
Donna = require '../src/donna'
Parser  = require '../src/parser'
Metadata = require '../src/metadata'

_ = require 'underscore'

CoffeeScript = require 'coffee-script'

require 'jasmine-focused'
require 'jasmine-json'

describe "Metadata", ->
  parser = null

  constructDelta = (filename, hasReferences = false) ->
    generated = Donna.generateMetadata([filename])[0]
    delete generated.version
    delete generated.repository
    delete generated.main

    expected_filename = filename.replace(/\.coffee$/, '.json')
    expected = JSON.parse(fs.readFileSync(expected_filename, 'utf8'))

    expect(generated).toEqualJson(expected)

  beforeEach ->
    parser = new Parser({
      inputs: []
      output: ''
      extras: []
      readme: ''
      title: ''
      quiet: false
      private: true
      verbose: true
      metadata: true
      github: ''
    })

  describe "Classes", ->
    it 'understands descriptions', ->
      constructDelta("spec/metadata_templates/classes/basic_class.coffee")

    it 'understands subclassing', ->
      constructDelta("spec/metadata_templates/classes/class_with_super_class.coffee")

    it 'understands class properties', ->
      constructDelta("spec/metadata_templates/classes/class_with_class_properties.coffee")

    it 'understands prototype properties', ->
      constructDelta("spec/metadata_templates/classes/class_with_prototype_properties.coffee")

    it 'understands comment sections properties', ->
      constructDelta("spec/metadata_templates/classes/class_with_comment_section.coffee")

    it 'selects the correct doc string for each function', ->
      constructDelta("spec/metadata_templates/classes/classes_with_similar_methods.coffee")

    it 'preserves comment indentation', ->
      constructDelta("spec/metadata_templates/classes/class_with_comment_indentation.coffee")

  describe "Exports", ->
    it 'understands basic exports', ->
      constructDelta("spec/metadata_templates/exports/basic_exports.coffee")

    it 'understands class exports', ->
      constructDelta("spec/metadata_templates/exports/class_exports.coffee")

  describe "Requires", ->
    it 'understands basic requires', ->
      constructDelta("spec/metadata_templates/requires/basic_requires.coffee")

    it 'understands multiple requires on a single line', ->
      constructDelta("spec/metadata_templates/requires/multiple_requires_single_line.coffee")

    it 'understands requires with a colon', ->
      constructDelta("spec/metadata_templates/requires/requires_with_colon.coffee")

    it 'understands importing', ->
      constructDelta("spec/metadata_templates/requires/references/buffer-patch.coffee")

  describe "when metadata is generated from multiple packages", ->
    it 'each slug contains only those files in the respective packages', ->
      singleFile = "spec/metadata_templates/requires/multiple_requires_single_line.coffee"
      realPackagePath = path.join("spec", "metadata_templates", "test_package")

      metadata = Donna.generateMetadata([singleFile, realPackagePath])

      expect(_.keys metadata[0].files).toEqual ['multiple_requires_single_line.coffee']
      expect(_.keys metadata[1].files).not.toContain 'multiple_requires_single_line.coffee'

  describe "A real package", ->
    it "renders the package correctly", ->
      test_path = path.join("spec", "metadata_templates", "test_package")
      slug = Donna.generateMetadata([test_path])[0]

      expected_filename = path.join(test_path, 'test_metadata.json')
      expected = JSON.parse(fs.readFileSync(expected_filename, 'utf8'))

      expect(slug).toEqualJson expected
      expect(_.keys(slug.files)).not.toContain "./Gruntfile.coffee"
      expect(_.keys(slug.files)).not.toContain "./spec/text-buffer-spec.coffee"
