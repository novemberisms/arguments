local lust = require "lust.lust"
local describe, it, expect, before = lust.describe, lust.it, lust.expect, lust.before

local Arguments = require "../arguments"
local fake_arg = {}
Arguments:setArgTable(fake_arg)

local function passArguments(...)
  for i, v in ipairs({...}) do
    fake_arg[i] = v
  end
end

describe("Arguments Library", function()
  before(function()
    for i = #fake_arg, 1, -1 do
      fake_arg[i] = nil
    end
    Arguments:reset()
  end)

  it("can recognize a basic pattern", function()
    passArguments("source.txt", "dest.txt", "Hello")
    Arguments:pattern("source_file dest_file message")
    expect(Arguments.source_file).to.be("source.txt")
    expect(Arguments.dest_file).to.be("dest.txt")
    expect(Arguments.message).to.be("Hello")
  end)

  it("should error if a required argument is not given", function()
    passArguments("source.txt", "dest.txt")
    expect(function()
      Arguments:pattern("source_file dest_file message")
    end).to.fail()
  end)

  it("can omit optional arguments", function()
    passArguments("source.txt", "dest.txt")
    Arguments:pattern("source_file dest_file [message]")
    expect(Arguments.message).to_not.exist()
  end)

  it("can access optional arguments", function()
    passArguments("source.txt", "dest.txt", "optional")
    Arguments:pattern("source_file dest_file [message]")
    expect(Arguments.message).to.be("optional")
  end)

  it("optional arguments can have a default value", function()
    passArguments("source.txt", "dest.txt")
    Arguments:pattern("source_file dest_file [ignore] [message=default] [n=99]")
    expect(Arguments.ignore).to.be(nil)
    expect(Arguments.message).to.be("default")
    expect(Arguments.n).to.be("99")
  end)

  it("required arguments cannot have a default value", function()
    passArguments("source.txt", "dest.txt")
    expect(function()
      Arguments:pattern("source_file dest_file=whoa.txt")
    end).to.fail()
  end)

  it("should ignore additional arguments", function()
    passArguments("source.txt", "dest.txt", "optional message", "ignore me!")
    Arguments:pattern("source_file dest_file [message]")
  end)

  it("required arguments cannot appear after optional arguments", function()
    passArguments("source.txt", "dest.txt", "optional message")
    expect(function()
      Arguments:pattern("source_file [dest_file] message")
    end).to.fail()
  end)

  it("should error if required parameter names are repeated", function()
    passArguments("source.txt", "dest.txt", "optional")
    expect(function()
      Arguments:pattern("source_file source_file [message]")
    end).to.fail()
  end)

  it("should error if optional parameter names are repeated", function()
    passArguments("source.txt", "optional", "again")
    expect(function()
      Arguments:pattern("source_file [message] [message]")
    end).to.fail()
    expect(function()
      Arguments:pattern("source_file [source_file] [message]")
    end).to.fail()
  end)

  it("can register and recognize flags", function()
    passArguments("source.txt", "dest.txt", "optional", "-v")
    Arguments:pattern("source_file dest_file [message]")
    Arguments:flag("verbose", "-v")
    Arguments:flag("help", "-h")
    expect(Arguments.verbose).to.be(true)
    expect(Arguments.help).to.be(false)
  end)

  it("flags should not be confused with optional parameters", function()
    passArguments("source.txt", "dest.txt", "-v")
    Arguments:pattern("source_file dest_file [message]")
    Arguments:flag("verbose", "-v")
    expect(Arguments.verbose).to.be(true)
    expect(Arguments.message).to.be(nil)
  end)

  it("flags should not be confused with optional parameters with default values", function()
    passArguments("source.txt", "dest.txt", "-v")
    Arguments:pattern("source_file dest_file [message=hello]")
    Arguments:flag("verbose", "-v")
    expect(Arguments.verbose).to.be(true)
    expect(Arguments.message).to.be("hello")
  end)

  it("flags can have a default value", function()
    passArguments("main.c")
    Arguments:pattern("source_file")
    Arguments:flag("optimization", "-O", 2)
    expect(Arguments.optimization).to.be(2)
  end)

  it("flags can have their default value overriden", function()
    passArguments("main.c", "-O=3")
    Arguments:pattern("source_file")
    Arguments:flag("optimization", "-O", 2)
    expect(Arguments.optimization).to.be(3)
  end)

  it("can use the allFlags method to iterate over all flag symbols in the arguments", function()
    passArguments("main.c", "-O=3", "-debug", "-level=95", "-playerSave=melmo")
    Arguments:pattern("source_file")
    Arguments:flag("optimization", "-O", 2)
    expect(Arguments:allFlags()).to.equal {
      ["-O"] = 3,
      ["-debug"] = true,
      ["-level"] = 95,
      ["-playerSave"] = "melmo",
    }
  end)
  
end)