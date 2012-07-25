local modname = ...
local Interface = {}
_G[modname] = Interface
package.loaded[modname] = Interface


local array = require("ljarray.array")
local ffi   = require("ffi")
local bit = require("bit")
local png   = ffi.load("png")


--[a lot of cdefs]
ffi.cdef[[
struct _IO_FILE;
typedef struct _IO_FILE FILE;
typedef FILE * png_FILE_p;

typedef unsigned char png_byte;
typedef png_byte * png_bytep;
typedef png_bytep * png_bytepp;

struct png_info;
typedef struct png_info * png_infop;
typedef png_infop * png_infopp;

/*struct struct_png_struct_def;*/
struct png_struct;
typedef struct png_struct * png_structp;
typedef png_structp * png_structpp;

typedef const char * png_const_charp;
typedef void * png_voidp;
typedef void (*png_error_ptr)(png_structp, png_const_charp);

typedef size_t png_size_t;
typedef uint32_t png_uint_32;
]]

--[enums]

ffi.cdef[[
enum {
  PNG_COLOR_MASK_PALETTE    = 1, /* 001 */
  PNG_COLOR_MASK_COLOR      = 2, /* 010 */
  PNG_COLOR_MASK_ALPHA      = 4, /* 100 */

  PNG_COLOR_TYPE_GRAY       = 0, /* 000 */
  PNG_COLOR_TYPE_PALETTE    = (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_PALETTE), /* 011 */
  PNG_COLOR_TYPE_RGB        = PNG_COLOR_MASK_COLOR, /* 010 */
  PNG_COLOR_TYPE_RGB_ALPHA  = (PNG_COLOR_MASK_COLOR | PNG_COLOR_MASK_ALPHA), /* 110 */
  PNG_COLOR_TYPE_GRAY_ALPHA = (PNG_COLOR_MASK_ALPHA) /* 100 */
} PNG_COLOR_TYPE;

enum {
  PNG_INTERLACE_NONE = 0,
  PNG_INTERLACE_ADAM7 = 1,
  PNG_INTERLACE_LAST  = 2
} PNG_INTERLACE;

enum {
  PNG_COMPRESSION_TYPE_BASE = 0
} PNG_COMPRESSION;

enum{
  PNG_FILTER_TYPE_BASE = 0
} PNG_FILTER;

enum{
  PNG_TRANSFORM_IDENTITY = 0
} PNG_TRANSFORMATION;

]]

--[readfunctions]
ffi.cdef[[

FILE * fopen(const char * filename, const char* mode);
size_t fread(void * ptr, size_t size, size_t count, FILE * stream);
int fclose (FILE * stream);


int png_sig_cmp(png_bytep sig, png_size_t start, png_size_t num_to_check);

png_structp png_create_read_struct(png_const_charp user_png_ver, png_voidp error_ptr,
  png_error_ptr error_fn, png_error_ptr warn_fn);

png_infop png_create_info_struct(png_structp png_ptr);

void png_init_io(png_structp png_ptr, png_FILE_p fp);

void png_set_sig_bytes(png_structp png_ptr, int num_bytes);

void png_read_info(png_structp png_ptr, png_infop info_ptr);

void png_destroy_read_struct(png_structpp png_ptr, png_infopp info_ptr_ptr, png_infopp end_info_ptr_ptr);

png_uint_32 png_get_image_width(png_structp png_ptr, png_infop info_ptr);

png_uint_32 png_get_image_height(png_structp png_ptr, png_infop info_ptr);

png_byte png_get_color_type(png_structp png_ptr, png_infop info_ptr);

png_byte png_get_bit_depth(png_structp png_ptr, png_infop info_ptr);

int png_set_interlace_handling(png_structp png_str);

void png_read_update_info(png_structp png_ptr, png_infop info_ptr);

void png_read_image(png_structp png_ptr, png_bytepp image);

png_uint_32 png_get_rowbytes(png_structp png_ptr, png_infop info_ptr);

void png_read_row(png_structp png_ptr, png_bytep row, png_bytep display_row);

void png_read_end(png_structp png_ptr, png_infop info_ptr);

void png_set_rows(png_structp png_ptr, png_infop info_ptr, png_bytepp row_pointers);

void png_read_png(png_structp png_ptr, png_infop info_ptr, int transformations, png_voidp params);



]]

--[writefunctions]
ffi.cdef[[
png_structp png_create_write_struct(png_const_charp user_png_ver, png_voidp error_ptr,\
png_error_ptr error_fn, png_error_ptr warn_fn);

void png_write_info(png_structp png_ptr, png_infop info_ptr);

void png_set_IHDR(png_structp png_ptr,\
png_infop info_ptr, png_uint_32 width, png_uint_32 height, int bit_depth,

int color_type, int interlace_method, int compression_method,\
int filter_method);

void png_write_png(png_structp png_ptr, png_infop info_ptr, int transformations, png_voidp params);

void png_destroy_write_struct(png_structpp png_ptr, png_infopp info_ptr_ptr);

void png_set_gray_to_rgb(png_structp png_ptr);

]]

--[extra utility]
ffi.cdef[[

typedef void (*png_row_callback) (png_structp, png_uint_32, int);

void png_set_read_status_fn(png_structp png_ptr, png_row_callback read_row_callback);

void png_set_write_status_fn(png_structp png_ptr, png_row_callback read_row_callback);

png_uint_32 png_access_version_number();

typedef struct png_handles {
  png_structp png_ptr;
  png_infop info_ptr;
  png_infop end_info_ptr;
}; 



]]

local read_row_callback = function(png_ptr, row, pass)
  print(row)
end

--Careful, initialize unused pointers with 0!
local handle_wrapper = ffi.metatype("struct png_handles", {
  
  gc = function(self) 
  png.png_destroy_read_struct(self.png_ptr, self.info_ptr, self.end_info_ptr)
end
})



--[lua conversions etc.]
local NULL = ffi.cast("void *", 0)
local PNG_LIBPNG_VER_STRING = tostring(png.png_access_version_number())

local bitdepth = {
  [1] = Array.uint8,
  [2] = Array.uint8,
  [4] = Array.uint8,
  [8] = Array.uint8,
  [16] = Array.uint16,
}

local colortable = {
  [ffi.C.PNG_COLOR_TYPE_GRAY] = 1,
  [ffi.C.PNG_COLOR_TYPE_GRAY_ALPHA] = 2,
  [ffi.C.PNG_COLOR_TYPE_RGB] = 3,
  [ffi.C.PNG_COLOR_TYPE_RGB_ALPHA] = 4
}
local reverse_colortable = {
  [1] = ffi.C.PNG_COLOR_TYPE_GRAY,
  [2] = ffi.C.PNG_COLOR_TYPE_GRAY_ALPHA,
  [3] = ffi.C.PNG_COLOR_TYPE_RGB,
  [4] = ffi.C.PNG_COLOR_TYPE_RGB_ALPHA
}
local function get_png_info(png_ptr, info_ptr)
  local width = png.png_get_image_width(png_ptr, info_ptr)
  local height = png.png_get_image_height(png_ptr, info_ptr)
  local color_type = png.png_get_color_type(png_ptr, info_ptr)
  local bit_depth = png.png_get_bit_depth(png_ptr, info_ptr)
  return width, height, color_type, bit_depth

end
local png_read = function(fp, png_ptr, info_ptr, end_info_ptr)

  local header = ffi.new("char[8]")
  ffi.C.fread(header, 1, 8, fp);
  if png.png_sig_cmp(header, 0, 8) ~= 0 then
    error("[read_png_file]" .. file_name .." is not recognized as a PNG file")
  end

  png.png_init_io(png_ptr, fp)
  png.png_set_sig_bytes(png_ptr, 8)
  png.png_read_info(png_ptr, info_ptr)

  local width, height, color_type, bit_depth = 
    get_png_info(png_ptr, info_ptr)
  local number_of_passes = png.png_set_interlace_handling(png_ptr);
  --print(width, height, color_type, bit_depth, number_of_passes)
  png.png_read_update_info(png_ptr, info_ptr)

  local num_entries = colortable[color_type]
  if not num_entries then
    error(color_type.. " color_type is currently not supported")
  end
  local shape = {width, height, colortable[color_type]}
  local dtype = bitdepth[bit_depth]
  local order = 'c'
  local arr = array.create(shape, dtype, order) 
  local row_pointers = ffi.new("png_bytep[?]", height)
  --print(width, height, color_type, bit_depth, shape)
  for i = 0, height - 1 do
    row_pointers[i] = ffi.cast("png_bytep", arr.data) + width * i * colortable[color_type]* (bit_depth / 8)
  end

  --png.png_set_rows(png_ptr, info_ptr, row_pointers) --see next line
  --png.png_read_png(png_ptr, info_ptr, 0, NULL) --doesn't work for some reason,
  --invalid chunks?

  --png.png_set_read_status_fn(png_ptr, ffi.new("png_row_callback", read_row_callback)) --hook, if necessary for debugging

  for i = 1, number_of_passes do
    png.png_read_image(png_ptr, row_pointers) 
  end
  png.png_read_end(png_ptr, end_info_ptr)

  return arr
end




local png_write = function(fp, png_ptr, info_ptr, array)

  png.png_init_io(png_ptr, fp)
  local width = array.shape[0]
  local height= array.shape[1]
  local elems = array.shape[2]
  local bit_depth = ffi.sizeof(array.element_type) * 8
  if bit.band(bit_depth, 24) == 0 then --Only 8 and 16 bit supported, currently
    error(bit_depth .. " bitdepth not supported")
  end
  local color_type = reverse_colortable[elems]
  if not color_type then
    error(elems .. " entries per pixel is currently not supported")
  end

  --[[if color_type == tonumber(ffi.C.PNG_COLOR_TYPE_GRAY) then
  if bit_depth < 8 then
  png_set_gray_1_2_4_to_8(png_ptr)
  end
  end
  --]]

  png.png_set_IHDR(png_ptr, info_ptr, width, height, bit_depth, color_type,
  ffi.C.PNG_INTERLACE_NONE, ffi.C.PNG_COMPRESSION_TYPE_BASE, ffi.C.PNG_FILTER_TYPE_BASE)

  --[[
  local width, height, color_type, bit_depth = 
    get_png_info(png_ptr, info_ptr)
  print(width, height, color_type, bit_depth, number_of_passes)
  ]]--

  local row_pointers = ffi.new("png_bytep[?]", height)
  for i = 0, height - 1 do
    row_pointers[i] = ffi.cast("png_bytep", array.data) + width * i * elems * (bit_depth / 8)
  end

  --png.png_set_write_status_fn(png_ptr, ffi.new("png_row_callback", read_row_callback))

  png.png_set_rows(png_ptr, info_ptr, row_pointers)
  png.png_write_png(png_ptr, info_ptr, ffi.C.PNG_TRANSFORM_IDENTITY, NULL)


end

local png_init = function(file_name, mode)

  local rawpointer = ffi.C.fopen(file_name, mode)

  if rawpointer == NULL then 
    local errorstring = "[png_init] " .. file_name .. " could not be opened, mode: " .. mode
    error(errorstring)
  end
  local fp = ffi.gc(rawpointer, ffi.C.fclose)
  local h = handle_wrapper(NULL, NULL, NULL)

  if mode:find('r') then
    h.png_ptr = png.png_create_read_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)
  elseif mode:find('w') then
    h.png_ptr = png.png_create_write_struct(PNG_LIBPNG_VER_STRING, NULL, NULL, NULL)
  else
    error("file operation " .. mode .. " not supported")
  end
  h.info_ptr = png.png_create_info_struct(h.png_ptr)
  h.end_info_ptr = png.png_create_info_struct(h.png_ptr)

  return fp, h
end


Interface.read_file = function(file_name)
  local err = nil
  local array = nil
  do
    local fp, h = png_init(file_name, "rb")
    err, array = pcall(png_read, fp, h.png_ptr, h.info_ptr, h.end_info_ptr)
  end
  collectgarbage()
  if not err then error(array) end
  return array
end


Interface.write_file = function(array, file_name)
  local err = nil
  local msg = nil
  do
    local fp, h = png_init(file_name, "wb")
    err, msg = pcall(png_write, fp, h.png_ptr, h.info_ptr, array)
  end
  collectgarbage()
  if not err then error(msg) end
end
