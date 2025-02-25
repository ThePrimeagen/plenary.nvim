local Path = require("plenary.path")
local path = Path.path

describe('Path', function()
  it('should find valid files', function()
    local p = Path:new("README.md")
    assert(p.filename == "README.md", p.filename)
    assert.are.same(p.filename, "README.md")
  end)

  describe('absolute', function()
    it('.absolute()', function()
      local p = Path:new { "README.md" , sep = '/'}
      assert.are.same(p:absolute(), vim.fn.fnamemodify("README.md", ":p"))
    end)

    it('can determine absolute paths', function()
      local p = Path:new { "/home/asdfasdf/" , sep = '/'}
      assert(p:is_absolute(), "Is absolute")
      assert(p:absolute() == p.filename)
    end)

    it('can determine non absolute paths', function()
      local p = Path:new { "./home/tj/" , sep = '/'}
      assert(not p:is_absolute(), "Is absolute")
    end)
  end)

  it('can join paths by constructor or join path', function()
    assert.are.same(Path:new("lua", "plenary"), Path:new("lua"):joinpath("plenary"))
  end)

  it('can join paths with /', function()
    assert.are.same(Path:new("lua", "plenary"), Path:new("lua") / "plenary")
  end)

  it('can join paths with paths', function()
    assert.are.same(Path:new("lua", "plenary"), Path:new("lua", Path:new("plenary")))
  end)

  it('inserts slashes', function()
    assert.are.same(
    'lua' .. path.sep .. 'plenary',
      Path:new("lua", "plenary").filename
    )
  end)

  describe('.exists()', function()
    it('finds files that exist', function()
      assert.are.same(true, Path:new("README.md"):exists())
    end)

    it('returns false for files that do not exist', function()
      assert.are.same(false, Path:new("asdf.md"):exists())
    end)
  end)

  describe('.is_dir()', function()
    it('should find directories that exist', function()
      assert.are.same(true, Path:new("lua"):is_dir())
    end)

    it('should return false when the directory does not exist', function()
      assert.are.same(false, Path:new("asdf"):is_dir())
    end)

    it('should not show files as directories', function()
      assert.are.same(false, Path:new("README.md"):is_dir())
    end)
  end)

  describe('.is_file()', function()
    it('should not allow directories', function()
      assert.are.same(true, not Path:new("lua"):is_file())
    end)

    it('should return false when the file does not exist', function()
      assert.are.same(true, not Path:new("asdf"):is_file())
    end)

    it('should show files as file', function()
      assert.are.same(true, Path:new("README.md"):is_file())
    end)
  end)

  describe(':new', function()
    it('can be called with or without colon', function()
    -- This will work, cause we used a colon
    local with_colon = Path:new('lua')
    local no_colon = Path.new('lua')

    assert.are.same(with_colon, no_colon)
    end)
  end)

  describe(':make_relative', function()
    it('can take absolute paths and make them relative to the cwd', function()
      local p = Path:new { 'lua', 'plenary', 'path.lua' }
      local absolute = vim.loop.cwd() .. path.sep .. p.filename
      local relative = Path:new(absolute):make_relative()
      assert.are.same(relative, p.filename)
    end)

    it('can take absolute paths and make them relative to a given path', function()
      local root = path.sep == "\\" and "c:\\" or "/"
      local r = Path:new { root, 'home', 'prime' }
      local p = Path:new { 'aoeu', 'agen.lua'}
      local absolute = r.filename .. path.sep .. p.filename
      local relative = Path:new(absolute):make_relative(r.filename)
      assert.are.same(relative, p.filename)
    end)

    it('can take double separator absolute paths and make them relative to the cwd', function()
      local p = Path:new { 'lua', 'plenary', 'path.lua' }
      local absolute = vim.loop.cwd() .. path.sep .. path.sep .. p.filename
      local relative = Path:new(absolute):make_relative()
      assert.are.same(relative, p.filename)
    end)

    it('can take double separator absolute paths and make them relative to a given path', function()
      local root = path.sep == "\\" and "c:\\" or "/"
      local r = Path:new { root, 'home', 'prime' }
      local p = Path:new { 'aoeu', 'agen.lua'}
      local absolute = r.filename .. path.sep .. path.sep .. p.filename
      local relative = Path:new(absolute):make_relative(r.filename)
      assert.are.same(relative, p.filename)
    end)

    it('can take absolute paths and make them relative to a given path with trailing separator', function()
      local root = path.sep == "\\" and "c:\\" or "/"
      local r = Path:new { root, 'home', 'prime' }
      local p = Path:new { 'aoeu', 'agen.lua'}
      local absolute = r.filename .. path.sep .. p.filename
      local relative = Path:new(absolute):make_relative(r.filename .. path.sep)
      assert.are.same(relative, p.filename)
    end)

    it('can take absolute paths and make them relative to the root directory', function()
      local root = path.sep == "\\" and "c:\\" or "/"
      local p = Path:new { 'home', 'prime', 'aoeu', 'agen.lua'}
      local absolute = root .. p.filename
      local relative = Path:new(absolute):make_relative(root)
      assert.are.same(relative, p.filename)
    end)

    it('can take absolute paths and make them relative to themselves', function()
      local root = path.sep == "\\" and "c:\\" or "/"
      local p = Path:new { root, 'home', 'prime', 'aoeu', 'agen.lua'}
      local relative = Path:new(p.filename):make_relative(p.filename)
      assert.are.same(relative, ".")
    end)
  end)

  describe(':normalize', function()
    it('can take paths with double separators change them to single separators', function()
      local orig = 'lua//plenary/path.lua'
      local final = Path:new(orig):normalize()
      assert.are.same(final, 'lua/plenary/path.lua')
    end)
    -- this may be redundant since normalize just calls make_relative which is tested above
    it('can take absolute paths with double seps'
      .. 'and make them relative with single seps', function()
      local orig = vim.loop.cwd() .. '/lua//plenary/path.lua'
      local final = Path:new(orig):normalize()
      assert.are.same(final, 'lua/plenary/path.lua')
    end)
  end)

  describe('mkdir / rmdir', function()
    it('can create and delete directories', function()
      local p = Path:new("_dir_not_exist")

      p:rmdir()
      assert(not p:exists(), "After rmdir, it should not exist")

      p:mkdir()
      assert(p:exists())

      p:rmdir()
      assert(not p:exists())
    end)

    it('fails when exists_ok is false', function()
      local p = Path:new("lua")
      assert(not pcall(p.mkdir, p, { exists_ok = false }))
    end)

    it('fails when parents is not passed', function()
      local p = Path:new("impossible", "dir")
      assert(not pcall(p.mkdir, p, { parents = false }))
      assert(not p:exists())
    end)

    it('can create nested directories', function()
      local p = Path:new("impossible", "dir")
      assert(pcall(p.mkdir, p, { parents = true }))
      assert(p:exists())

      p:rmdir()
      Path:new('impossible'):rmdir()
      assert(not p:exists())
      assert(not Path:new('impossible'):exists())
    end)
  end)

  describe('touch', function()
    it('can create and delete new files', function()
      local p = Path:new("test_file.lua")
      assert(pcall(p.touch, p))
      assert(p:exists())

      p:rm()
      assert(not p:exists())
    end)

    it('does not effect already created files but updates last access', function()
      local p = Path:new("README.md")
      local last_atime = p:_stat().atime.sec
      local last_mtime = p:_stat().mtime.sec

      local lines = p:readlines()

      assert(pcall(p.touch, p))
      print(p:_stat().atime.sec > last_atime)
      print(p:_stat().mtime.sec > last_mtime)
      assert(p:exists())

      assert.are.same(lines, p:readlines())
    end)

    it('does not create dirs if nested in none existing dirs and parents not set', function()
      local p = Path:new({ "nested", "nested2", "test_file.lua" })
      assert(not pcall(p.touch, p, { parents = false }))
      assert(not p:exists())
    end)

    it('does create dirs if nested in none existing dirs', function()
      local p1 = Path:new({ "nested", "nested2", "test_file.lua" })
      local p2 = Path:new({ "nested", "asdf", ".hidden" })
      assert(pcall(p1.touch, p1, { parents = true }))
      assert(pcall(p2.touch, p2, { parents = true }))
      assert(p1:exists())
      assert(p2:exists())

      Path:new({ "nested" }):rm({ recursive = true })
      assert(not p1:exists())
      assert(not p2:exists())
      assert(not Path:new({ "nested" }):exists())
    end)
  end)

  describe('rename', function()
    it('can rename a file', function()
      local p = Path:new("a_random_filename.lua")
      assert(pcall(p.touch, p))
      assert(p:exists())

      assert(pcall(p.rename, p, { new_name = "not_a_random_filename.lua" }))
      assert.are.same("not_a_random_filename.lua", p.filename)

      p:rm()
    end)

    it('can handle an invalid filename', function()
      local p = Path:new("some_random_filename.lua")
      assert(pcall(p.touch, p))
      assert(p:exists())

      assert(not pcall(p.rename, p, { new_name = "" }))
      assert(not pcall(p.rename, p))
      assert.are.same("some_random_filename.lua", p.filename)

      p:rm()
    end)

    it('can move to parent dir', function()
      local p = Path:new("some_random_filename.lua")
      assert(pcall(p.touch, p))
      assert(p:exists())

      assert(pcall(p.rename, p, { new_name = "../some_random_filename.lua" }))
      assert.are.same(vim.loop.fs_realpath(Path:new("../some_random_filename.lua"):absolute()), p:absolute())

      p:rm()
    end)

    it('cannot rename to an existing filename', function()
      local p1 = Path:new("a_random_filename.lua")
      local p2 = Path:new("not_a_random_filename.lua")
      assert(pcall(p1.touch, p1))
      assert(pcall(p2.touch, p2))
      assert(p1:exists())
      assert(p2:exists())

      assert(not pcall(p1.rename, p1, { new_name = "not_a_random_filename.lua" }))
      assert.are.same(p1.filename, "a_random_filename.lua")

      p1:rm()
      p2:rm()
    end)
  end)

  describe('copy', function()
    it('can copy a file', function()
      local p1 = Path:new("a_random_filename.rs")
      local p2 = Path:new("not_a_random_filename.rs")
      assert(pcall(p1.touch, p1))
      assert(p1:exists())

      assert(pcall(p1.copy, p1, { destination = "not_a_random_filename.rs" }))
      assert.are.same(p1.filename, "a_random_filename.rs")
      assert.are.same(p2.filename, "not_a_random_filename.rs")

      p1:rm()
      p2:rm()
    end)

    it('can copy to parent dir', function()
      local p = Path:new("some_random_filename.lua")
      assert(pcall(p.touch, p))
      assert(p:exists())

      assert(pcall(p.copy, p, { destination = "../some_random_filename.lua" }))
      assert(pcall(p.exists, p))

      p:rm()
      Path:new(vim.loop.fs_realpath("../some_random_filename.lua")):rm()
    end)

    it('cannot copy a file if it\'s already exists' , function()
      local p1 = Path:new("a_random_filename.rs")
      local p2 = Path:new("not_a_random_filename.rs")
      assert(pcall(p1.touch, p1))
      assert(pcall(p2.touch, p2))
      assert(p1:exists())
      assert(p2:exists())

      assert(pcall(p1.copy, p1, { destination = "not_a_random_filename.rs" }))
      assert.are.same(p1.filename, "a_random_filename.rs")
      assert.are.same(p2.filename, "not_a_random_filename.rs")

      p1:rm()
      p2:rm()
    end)
  end)

  describe('parents', function()
    it('should extract the ancestors of the path', function()
      local p = Path:new(vim.loop.cwd())
      local parents = p:parents()
      assert(vim.tbl_islist(parents))
      for _, parent in pairs(parents) do
        assert.are.same(type(parent), 'string')
      end
    end)
    it('should return itself if it corresponds to path.root', function()
      local p = Path:new(Path.path.root(vim.loop.cwd()))
      assert.are.same(p:parent(), p.filename)
    end)
  end)

  describe('read parts', function()
    it('should read head of file', function()
      local p = Path:new('LICENSE')
      local data = p:head()
      local should = [[MIT License

Copyright (c) 2020 TJ DeVries

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:]]
      assert.are.same(should, data)
    end)

    it('should read the first line of file', function()
      local p = Path:new('LICENSE')
      local data = p:head(1)
      local should = [[MIT License]]
      assert.are.same(should, data)
    end)

    it('head should max read whole file', function()
      local p = Path:new('LICENSE')
      local data = p:head(1000)
      local should = [[MIT License

Copyright (c) 2020 TJ DeVries

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]
      assert.are.same(should, data)
    end)

    it('should read tail of file', function()
      local p = Path:new('LICENSE')
      local data = p:tail()
      local should = [[The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]
      assert.are.same(should, data)
    end)

    it('should read the last line of file', function()
      local p = Path:new('LICENSE')
      local data = p:tail(1)
      local should = [[SOFTWARE.]]
      assert.are.same(should, data)
    end)

    it('tail should max read whole file', function()
      local p = Path:new('LICENSE')
      local data = p:tail(1000)
      local should = [[MIT License

Copyright (c) 2020 TJ DeVries

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.]]
      assert.are.same(should, data)
    end)
  end)
end)


-- function TestPath:testIsDir()
-- end

-- function TestPath:testCanBeCalledWithoutColon()
-- end

-- -- @sideeffect
-- function TestPath:testMkdir()
-- end
