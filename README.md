# Content History Technical Diff Prototype

## Background

The objective is to build a prototype which can be used to show diffs between versions of content items, it is assumed that the audience of these are technical and thus are happy with diffs that reveal underlying things (such as json, line numbers, govspeak/html). The diffs will be inspired by how github diffs source code.

The prototype will have to:

- Find a way to access a variety of versions of content-items (maybe we export a bunch from Publishing API to JSON files)
- Utilise some sort of diffing library to show items
- Find ways to make the output as usable as possible
  - This might require deciding which fields should be shown for a particular document_type
  - Find ways to break up strings which have new lines in them (might mean using a different data format to JSON?

## Findings

- 
