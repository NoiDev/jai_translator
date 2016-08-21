/*

Clean up load_font vs get_font_at_size.

Is FT_Face_Internal by value? If so, how big is it?? (Do we care?)

get_kerning is broken (it breaks font rendering for KarminaBold at least).

isLegalUTF8 does not work.

*/

#import "freetype253";
#import "Hash_Table";

ft_library    : *FT_Library = null;
fonts_initted := false;          

/*
my_set_texture:    (*void) -> void,
my_create_texture: (*Bitmap_Data) -> void;
*/

// We probably should make different page sizes
// for different fonts.
the_font_page_size_x := 1024;
the_font_page_size_y := 1024;

my_back_buffer_width: s64 = 10000;
my_back_buffer_height: s64 = 10000;

// Wacky structures used in the font file format.

loaded_fonts  : [..] *Loaded_Font;
font_pages    : [..] *Font_Page;
dynamic_fonts : [..] *Dynamic_Font;

glyph_and_line_pool : Pool;

DUMMY_SOURCE_LENGTH :: 1000;  // This is stupid.

trailingBytesForUTF8 : [256] u8;
offsetsFromUTF8      : [6]   u32;

unicode_initted := false;

UNI_REPLACEMENT_CHAR: u32 = 0x0000FFFD;
UNI_MAX_BMP:          u32 = 0x0000FFFF;
UNI_MAX_UTF16:        u32 = 0x0010FFFF;
UNI_MAX_UTF32:        u32 = 0x7FFFFFFF;


unicode_init :: () {
    // @Cleanup: We need array literals so we don't need to do this!

    unicode_initted = true;

    for 192..223 trailingBytesForUTF8[it] = 1;
    for 224..239 trailingBytesForUTF8[it] = 2;
    for 240..247 trailingBytesForUTF8[it] = 3;
    for 248..251 trailingBytesForUTF8[it] = 4;
    for 252..255 trailingBytesForUTF8[it] = 5;


    offsetsFromUTF8[0] = 0;
    offsetsFromUTF8[1] = 0x00003080;
    offsetsFromUTF8[2] = 0x000E2080;
    offsetsFromUTF8[3] = 0x03C82080;
    offsetsFromUTF8[4] = 0xFA082080;
    offsetsFromUTF8[5] = 0x82082080;

/*

These are reproducing the following from C++:

char Unicode::trailingBytesForUTF8[256] = {
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
	1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1, 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
	2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2, 3,3,3,3,3,3,3,3,4,4,4,4,5,5,5,5
};

static const UTF32 offsetsFromUTF8[6] = { 0x00000000UL, 0x00003080UL, 0x000E2080UL, 
					 0x03C82080UL, 0xFA082080UL, 0x82082080UL };

*/


};


my_swap2 :: (mem: u16) -> u16 {
    a := mem >> 8;
    b := (mem & 0xff) << 8;

    return a | b;
}

my_swap4 :: (mem: u32) -> u32 {
    a := mem >> 24;
    b := mem >> 16;
    c := mem >> 8;
    d := mem;

    a = a & 0xff;
    b = b & 0xff;
    c = c & 0xff;
    d = d & 0xff;

    d = d << 24;
    c = c << 16;
    b = b << 8;

    return a | b | c | d;
}

isdigit :: (utf32: u32) -> bool {
    return (utf32 >= #char "0") && (utf32 <= #char "9");
}

Unicode_Result :: enum {
    CONVERSION_OK,
    SOURCE_EXHAUSTED,
    SOURCE_ILLEGAL,
}


isLegalUTF8 :: (source: *u8, length: s64) -> bool {
    if length == 0 return false;
    if length >  4  return false;

	srcptr := source+length;

    if length >= 4 {
        a := <<srcptr;
        srcptr -= 1;
        if a < 0x80 return false;
        if a > 0xBF return false;
    }

    if length >= 3 {
        a := <<srcptr;
        srcptr -= 1;
        if a < 0x80 return false;
        if a > 0xBF return false;
    }

    if length >= 2 {
        a := << srcptr;
        srcptr -= 1;
        if a > 0xBF return false;

        if << source == 0xE0 {
            if a < 0xA0 return false;
        } else if << source == 0xF0 {
            if a < 0x90 return false;
        } else if << source == 0xF4 {
            if a > 0x8F return false;
        } else {
            if a < 0x80 return false;
        }
    }

    if (<< source >= 0x80) && (<< source <= 0xC2) return false;
    if << source > 0xF4 return false;

    return true;
}



unicode_next_character :: (s: *u8) -> *u8 {
    bytes_for_this_character := 1 + trailingBytesForUTF8[<< s];
    return s + bytes_for_this_character;
}

character_utf8_to_utf32 :: (s: *u8, source_length: s64) -> u32, Unicode_Result.strict {
	source := s;

    ch : u32 = 0;

    extraBytesToRead := trailingBytesForUTF8[<< source];
    if extraBytesToRead + 1 > source_length {
        return UNI_REPLACEMENT_CHAR, Unicode_Result.SOURCE_EXHAUSTED;
    }

    /* Do this check whether lenient or strict */
/*
    Commented out because this is broken right now.

    if !isLegalUTF8(source, extraBytesToRead+1) {
        printf("Not legal!!!!!!!!!!!!\n");
        return UNI_REPLACEMENT_CHAR, Unicode_Result.SOURCE_ILLEGAL;
    }
*/

    for 1..extraBytesToRead {  // Do nothing if it is 0.
    	ch += << source; 
        ch = ch << 6;
        source += 1;
    }

    ch += << source;
    ch -= offsetsFromUTF8[extraBytesToRead];

    if ch > UNI_MAX_UTF32 {
        ch = UNI_REPLACEMENT_CHAR;
    }

	return ch, Unicode_Result.CONVERSION_OK;
}



FONT_EFFECT_SMALLCAPS      :: 0x1;
FONT_EFFECT_LINING_FIGURES :: 0x2;
FONT_EFFECT_NO_KERNING     :: 0x4;
FONT_EFFECT_LEFT_JUSTIFIED :: 0x8;

Glyph_Data :: struct {
    utf32: u32;
    glyph_index_within_font: u32;

    x0, y0: s16;
    width, height: s32;  // Freetype's structs are signed, so are we. Sigh.

    offset_x, offset_y: s16;

    ascent: s16;  // Mainly for descent, actually!
    advance: s16;

    page: *Font_Page;
};


Dynamic_Font :: struct {
    name: string;
    latin_font: *Dynamic_Font;

    glyph_lookup: *Hash_Table;

    private1: FT_Face;

    character_range_low:  int;
    character_range_high: int;

    character_height:       int;
    default_line_spacing:   int;
    y_offset_for_centering: float;
    y_offset_for_my_latin_characters: float;

    use_other_font_for_latin_always: bool;
    reversed: bool;  // True if this font is byte-order-reversed from its file....
    glyph_conversion_failed: bool;  // The most recent call to convert_to_temporary_glyphs() found a character it didn't know.

    features: [..] Font_Feature;

    feature_smallcaps:      *Font_Feature;
    feature_ligatures:      *Font_Feature;
    feature_lining_numbers: *Font_Feature;

    temporary_glyphs: [..] *Glyph_Data;
    temporary_glyphs_width_in_pixels: s64;
};


Font_Page :: struct {
    map:           *Texture_Map;
    bitmap_data:   *Bitmap;

    line_cursor_y: s16;
    lines:         [..] *Font_Line;

    dirty := false;
};

Font_Line :: struct {
    page: *Font_Page;

    bitmap_cursor_x: s16;
    bitmap_cursor_y: s16;

    height: int;
};

Loaded_Font :: struct {
    name: string;
    face: FT_Face;
};



Font_Range_Record :: struct {
    start, end: s32;
    start_coverage_index: s32;
};

Font_Coverage_Table :: struct {
    format: s64;

    glyphs: [] u16;   // If format 1.
    range_records: [] Font_Range_Record;  // If format 2.
};

Font_Lookup_Subtable :: struct {
    format: s64;
    coverage_table: *Font_Coverage_Table;

    delta_glyph_id: s64;     // If lookup type 1, table format 1
    glyphs: [] u16;          // If lookup type 1, table format 2
    sequence_table: [] Font_Sequence_Table_Entry;       // If lookup type 2, table format 1
};

Font_Sequence_Table_Entry :: struct {
    glyphs: [] u16;
};

Font_Lookup_Table :: struct {
    lookup_type:   s32;
    lookup_flags:  u32;

    subtables: [] Font_Lookup_Subtable;
};

Font_Feature :: struct {
    feature_tag: u32;
    feature_tables_pointer: *u8;
    expanded: bool;

    lookup_lists:  [] u16;
    lookup_tables: [] Font_Lookup_Table;
};




init_fonts :: (page_size_x: int, page_size_y: int
               /*, set_texture: (*void) -> void,
               create_texture: (*Bitmap_Data) -> void*/ ) {

    assert(page_size_x >= 64);
    assert(page_size_y >= 64);

    fonts_initted = true;
    the_font_page_size_x = page_size_x;
    the_font_page_size_y = page_size_y;

    error := FT_Init_FreeType(*ft_library);
    assert(!error);

    set_allocators(*glyph_and_line_pool);
    glyph_and_line_pool.memblock_size = 100 * size_of(Glyph_Data);

/*
    my_set_texture = set_texture;
    my_create_texture = create_texture;
*/
}


font_update_back_buffer_width :: (width: s64, height: s64) {
    my_back_buffer_width = width;
    my_back_buffer_height = height;
}

get_glyph_width_in_pixels :: (glyph: *Glyph_Data) -> s64 {
    return glyph.advance;
}

destroy :: (font: *Loaded_Font) {
    free(font.name.data);
}

init_font :: (using font: *Dynamic_Font) {
    glyph_lookup = new Hash_Table(200);
}


is_latin :: (utf32: u32) -> bool {
    if utf32 > 0x24F {  // 0x24F is the end of Latin Extended-B
        if (utf32 >= 0x2000) && (utf32 <= 0x218F) {  // General punctuation, currency symbols, number forms, etc.
        } else {
            return false;
        }
    }

    return true;
}


find_line_within_page :: (page: *Font_Page, width: int, height: int) -> *Font_Line {
    map := page.map;

    for page.lines {
        if it.height < height continue;  // Line too short!
        if ((it.height * 7) / 10) > height continue;  // Line too tall!

        if map.width - it.bitmap_cursor_x < width continue;  // No room at end of line!

        return it;  // Found one!
    }

    // If there's not enough room to start a new line, bail.
    height_remaining := map.height - page.line_cursor_y;
    if height_remaining < height return null;

    // Or if for some reason the page is too narrow for the character...
    // In this case, starting a new line would not help!
    if map.width < width return null;

    // Start a new line... With some extra space for expansion if we have room.
    desired_height := (height * 11) / 10;

    if desired_height > height_remaining desired_height = height_remaining;

    line : *Font_Line = get(*glyph_and_line_pool, size_of(Font_Line));
    if !line return null;

    line.page = page;
    line.bitmap_cursor_x = 0;
    line.bitmap_cursor_y = page.line_cursor_y;
    line.height = desired_height;

    array_add(*page.lines, line);

    page.line_cursor_y += cast(s16) desired_height;

    return line;
}

make_bitmap_data :: (w: s32, h: s32) -> *Bitmap {
    data := new Bitmap;

    bytes := w * h * 4;

    data.width = w;
    data.height = h;
    data.format = Texture_Format.ARGB8888;
    data.num_mipmap_levels = 1;
    data.length_in_bytes = bytes;
    data.data = alloc(bytes);

/*
//  Debugging code to fill the texture map with a checkerboard.
    int i, j;
    for (j = 0; j < h; j++) {
        for (i = 0; i < w; i++) {
            unsigned char *pixel = data->data + (j * w + i) * 4;
            if ((i * j) & 4) {
                pixel[0] = 0;
                pixel[1] = 0;
                pixel[2] = 0;
                pixel[3] = 255;
            } else {
                pixel[0] = 255;
                pixel[1] = 255;
                pixel[2] = 255;
                pixel[3] = 255;
            }
        }
    }
*/

    return data;
}

make_font_page :: () -> *Font_Page {
    page := new Font_Page;
  
    page.bitmap_data = make_bitmap_data(xx the_font_page_size_x, xx the_font_page_size_y);
  
    data := page.bitmap_data;
    page.map = create_texture(data);

    return page;
}

/*
ensure_font_textures_are_clean :: () {
    //
    // If the textures are dirty, we copy out only the relevant data...
    //

    for page : font_pages {
        if !bit_and(page.map.flags, Texture_Map.DIRTY) continue;
      
        display_refresh_texture(page.map, page.bitmap_data);

        page.map.flags = cast(u32) bit_and(page.map.flags, bit_not(Texture_Map.DIRTY));

        // @Incomplete: We could copy only the dirty regions...
    }
}
*/
    
get_font_line :: (width: int, height: int) -> *Font_Line {
    for page : font_pages {
        line := find_line_within_page(page, width, height);
        if line return line;
    }

    page := make_font_page();
    if !page return null;

    array_add(*font_pages, page);

    return find_line_within_page(page, width, height);  // If we didn't find it somehow, we lose!  
}

find_loaded_font :: (name: string) -> *Loaded_Font {
    for loaded_fonts {
        if it.name == name return it;
    }

    return null;
}

make_loaded_font :: (name: string, data: string) -> *Loaded_Font {
    face: FT_Face;

    error := FT_New_Memory_Face(ft_library, data.data, cast(s32) data.count,
                                0, *face);
    assert(error != FT_Err_Unknown_File_Format);
    assert(!error);

    if error return null;

    loaded_font := new Loaded_Font;
    loaded_font.name = copy_string(name);
    loaded_font.face = face;

    array_add(*loaded_fonts, loaded_font);

    return loaded_font;
}

make_loaded_font :: (name: string) -> (font: *Loaded_Font, bytes_loaded: s64) {
    s, success := read_entire_file(name);
    if !success return null, 0;

    font := make_loaded_font(name, s);

    return font, s.count;
}

/*
prep_loaded_font_from_package :: (path: string, basename: string) -> *Loaded_Font {
    ensure_fonts_are_initted();

    font_name := sprint("%1/%2", path, basename);
    defer free(font_name.data);

    data, length := read_entire_binary_file(font_name);
    if !data return null;

    buffer: [] u8;
    buffer.count = length;
    buffer.data = data;

    return make_loaded_font2(font_name, buffer);
}
*/


/*
get_field_from_info :: (info: *Type_Info, name: string) -> *Type_Info_Struct_Member {
    if info.type != Type_Info_Tag.STRUCT {
        printf("Error: Argument is not a struct.\n");
        return null;
    }

    info_struct := cast(*Type_Info_Struct) info;
    
    result := get_field(info_struct, name);
    
    if (!result) printf("Field '%s' not found.\n", name);
    return result;
}

print_offset :: (info: *Type_Info, name: string) {
    field := get_field(info, name);
    if field printf("offset of '%s' is %d\n", name, field.offset_in_bytes);
}
*/

copy_glyph_to_bitmap :: (face: FT_Face, data: *Glyph_Data) {
    b := *face.glyph.bitmap;

/*
    print_offset(type_info(FT_GlyphSlotRec), "advance");
    print_offset(type_info(FT_GlyphSlotRec), "format");
    print_offset(type_info(FT_GlyphSlotRec), "bitmap");

    printf("b.width %d, b.rows %d\n", b.width, b.rows);
*/

    data.width = b.width;
    data.height = b.rows;
    data.advance = cast(s16) (face.glyph.advance.x >> 6);   // @Cleanup: reduce the number of casts?
    data.offset_x = cast(s16) face.glyph.bitmap_left;
    data.offset_y = cast(s16) face.glyph.bitmap_top;

    metrics := *face.glyph.metrics;
    data.ascent = cast(s16) (metrics.horiBearingY >> 6);

    font_line := get_font_line(b.width, b.rows);
    if !font_line {
        // Fail! ... They get kind-of garbage.
        data.x0 = 0;
        data.y0 = 0;
        print("***** font_line is null, ugh.\n");
        assert(false);
        data.page = null;
        return;
    }

    dest_x := font_line.bitmap_cursor_x;
    dest_y := font_line.bitmap_cursor_y;

    data.x0 = dest_x;
    data.y0 = dest_y;
    data.page = font_line.page;

    bitmap := font_line.page.bitmap_data;

    for j : 0..b.rows-1 {
        for i : 0..b.width-1 {
            source_pixel := b.buffer[(b.rows - 1 - j) * b.pitch + i];

            dest_pixel := bitmap.data + ((dest_y + j) * bitmap.width + (dest_x + i)) * 4;
            dest_pixel[0] = 255;
            dest_pixel[1] = 255;
            dest_pixel[2] = 255;
            dest_pixel[3] = source_pixel;
        }
    }
    
    font_line.bitmap_cursor_x += cast(s16) b.width;
    font_line.page.dirty = true;
}

// @Hack XXXXXXXXXX Major Hack... we don't know how to convert glyph IDs to utf32, so for now we store some glyphs by negative-glyph-index in the hash table.  These may be dupes of entries we already have in there as utf32.  We ought to fix this!

get_hash_key :: (glyph_index: u32) -> int {
    return -cast(int)glyph_index;
}

find_or_create_glyph :: (using font: *Dynamic_Font, 
                         utf32: u32, glyph_index: u32, hash_key: int) -> *Glyph_Data {

    table := font.glyph_lookup;  // XXX Why not using?
    data := cast(*Glyph_Data) table_find(table, hash_key); // XXX Typecheck
    if (data) return data;

    face := font.private1;  // XXX Why not using?

    // @Move: Make this happen at font construction time.  @Speed.
    // However we can't right now, because we share this face among
    // multiple Dynamic_Fonts...

    error := FT_Set_Pixel_Sizes(face, 0, cast(u32) font.character_height);    // XXX WHy not using?
    assert(!error);


    if (utf32) {
        glyph_index = FT_Get_Char_Index(face, utf32);
        if (glyph_index) {
            FT_Load_Glyph(face, glyph_index, FT_LOAD_RENDER);
        }
    } else {
        // @Hack
        assert(glyph_index != 0);
        FT_Load_Glyph(face, glyph_index, FT_LOAD_RENDER);
    }

    data = cast(*Glyph_Data) get(*glyph_and_line_pool, size_of(Glyph_Data));
    data.utf32 = utf32;
    data.glyph_index_within_font = glyph_index;

    copy_glyph_to_bitmap(face, data);

    table_add(table, data, hash_key);

    return data;
}

find_or_create_glyph :: (font: *Dynamic_Font, utf32: u32) -> *Glyph_Data {
    return find_or_create_glyph(font, utf32, 0, utf32);
}

one_utf32_char :: inline (s: *u8) -> u32 {
    utf32 := character_utf8_to_utf32(s, DUMMY_SOURCE_LENGTH);  // @BufferLength @Robustness
    return utf32;
}

find_or_create_glyph_utf8 :: (font: *Dynamic_Font, utf8: *u8) -> *Glyph_Data {  // XXX Overloading
    utf32 := one_utf32_char(utf8);
    return find_or_create_glyph(font, utf32);
}

ensure_fonts_are_initted :: () {
    if !fonts_initted init_fonts(the_font_page_size_x, the_font_page_size_y);
    if !unicode_initted unicode_init();
}

prepare_for_kerning :: (using font: *Dynamic_Font) {
    face := font.private1;   // XXX Why not using?

    // We have to set the size because a different-sized Dynamic_Font, using
    // the same FT_Face, might have changed the size to kern or render glyphs.
    // Instead of having a manually-called function like this, we could cache
    // which Dynamic_Font last called FT_Set_Pixel_Sizes, storing this on the
    // Loaded_Font, and then set it dynamically from places like get_kerning().

    error := FT_Set_Pixel_Sizes(face, 0, cast(u32) font.character_height);   // XXX Why not using?
    assert(!error);
}

get_kerning :: (using font: *Dynamic_Font, prior: *Glyph_Data, current: *Glyph_Data, kerning_offset: *Vector2) {  // XXX Out parameter should become a return value.
    if (!prior) {
        kerning_offset.x = 0;
        kerning_offset.y = 0;
        return;
    }

    face := font.private1;  // XXX Why not using?
    has_kerning := FT_HAS_KERNING(face);

    index_left  := prior.glyph_index_within_font;
    index_right := current.glyph_index_within_font;

    kerning_mode := FT_KERNING_DEFAULT;

    // @Speed: Is FT_Set_Pixel_Sizes slow?  Do we want to do something about this?
//    int error;
//    error = FT_Set_Pixel_Sizes(face, 0, character_height);  
//    assert(!error);


    kerning: FT_Vector;
    error := FT_Get_Kerning(face, index_left, index_right,
                            kerning_mode, *kerning);

    if error {
        kerning_offset.x = 0;
        kerning_offset.y = 0;
    } else {
        kerning_offset.x = cast(float) (kerning.x >> 6);
        kerning_offset.y = cast(float) (kerning.y >> 6);
    }
}



// @Refactor: Factor this together with add_glyph_to_temporaries?
get_character_width_in_pixels :: (using font: *Dynamic_Font, utf8: *u8, effect_flags: u32) -> u32 {
    glyph := find_or_create_glyph_utf8(font, utf8);
    if !glyph return 0;

    font.temporary_glyphs.count = 0;
    array_add(*font.temporary_glyphs, glyph);

    if effect_flags do_glyph_substitutions(font, effect_flags);

    return cast(u32) font.temporary_glyphs[0].advance;
}

get_index_within_format_1_coverage_table :: (table: *Font_Coverage_Table, glyph: *Glyph_Data) -> s64 {
    // @Cleanup: This whole proc can be replaced by a generic array find.

    for table.glyphs
        if it == glyph.glyph_index_within_font 
            return it_index;

    return -1;
}

get_index_within_format_2_coverage_table :: (table: *Font_Coverage_Table, glyph: *Glyph_Data) -> s64 {
    glyph_id := cast(s32) glyph.glyph_index_within_font;  // Because record.* are s32... sigh.

    for table.range_records {
        if glyph_id < it.start continue;
        if glyph_id > it.end continue;

        delta := glyph_id - it.start;
        return it.start_coverage_index + delta;
    }

    return -1;
}

get_index_within_coverage_table :: (table: *Font_Coverage_Table, glyph: *Glyph_Data) -> s64 {
    if table.format == 1 return get_index_within_format_1_coverage_table(table, glyph);
    if table.format == 2 return get_index_within_format_2_coverage_table(table, glyph);

    assert(false);

    return -1;
}

single_substitute :: (using font: *Dynamic_Font, feature: *Font_Feature,
                      orig: *Glyph_Data) -> *Glyph_Data {

    if !feature return orig;

    orig_utf32 := orig.utf32;

    for * table : feature.lookup_tables {  // XXX Array simplify

        for * subtable : table.subtables {
            index := get_index_within_coverage_table(subtable.coverage_table, orig);
            if index == -1 return orig;

            if table.lookup_type == 1 {
                if subtable.format == 1 {  // SingleSubstFormat1
                    glyph_id := orig.glyph_index_within_font + cast(u32) subtable.delta_glyph_id;
                    new_glyph := find_or_create_glyph(font, 0, glyph_id, get_hash_key(glyph_id));
                    new_glyph.utf32 = orig_utf32;
                    return new_glyph;
                } else if subtable.format == 2 {  // SingleSubstFormat2
                    assert(index < subtable.glyphs.count);

                    glyph_id := subtable.glyphs[index];
                    new_glyph := find_or_create_glyph(font, 0, glyph_id, get_hash_key(glyph_id));

                    new_glyph.utf32 = orig_utf32;
                    return new_glyph;
                } else {
                    assert(false);
                }
            }

            if table.lookup_type == 2 {
                entry := *subtable.sequence_table[index];

                glyph_id := entry.glyphs[0];
                new_glyph := find_or_create_glyph(font, 0, glyph_id, get_hash_key(glyph_id));

                //
                // @Hack: If for some reason there was more than 1 glyph in this table,
                // we just use the first one... for now we are just using this for
                // SmallCaps so it should not be a big deal.
                //
                new_glyph.utf32 = orig_utf32;
                return new_glyph;
            }
        }
    }

    return orig;
}


accumulate_glyphs_from_font :: (source: *Dynamic_Font, dest: *Dynamic_Font) {
    for source.temporary_glyphs array_add(*dest.temporary_glyphs, it);
}

add_glyph_to_temporaries :: inline (font: *Dynamic_Font, glyph: *Glyph_Data) {

    array_add(*font.temporary_glyphs, glyph);
    font.temporary_glyphs_width_in_pixels += glyph.advance;

    //
    // FreeType returns glyph index 0 for undefined glyphs... just signal
    // the condition that this happened.
    //

    if glyph.glyph_index_within_font == 0 font.glyph_conversion_failed = true;
}

flush_my_latin_font :: (font: *Dynamic_Font, effect_flags: u32) {
    // Flush any latin characters in the Latin font back into the non-latin Font...

    latin_font := font.latin_font;
    assert(latin_font != null);

    if !latin_font.temporary_glyphs.count return;

    // add_glyph_to_temporaries(latin_font, latin_font.zero_glyph);  // XXX Why do we do this?
    // latin_font.temporary_glyphs.count -= 1;  // Since the zero glyph is not counted...

    do_glyph_substitutions(latin_font, effect_flags);
    accumulate_glyphs_from_font(latin_font, font);
    latin_font.temporary_glyphs.count = 0;
}


convert_to_temporary_glyphs :: (using font: *Dynamic_Font, s: string, effect_flags: u32) {  // XXX using
    glyph_conversion_failed = false;

    temporary_glyphs.count = 0;
    if latin_font latin_font.temporary_glyphs.count = 0;

    if !s return;

    original_string := s;
    sum := 0;

    temporary_glyphs_width_in_pixels = 0;

    all_latin := true;
    if !original_string.data  all_latin = false;  // Don't bother xreffing to latin font if the string is empty.

    t := s.data;
    while t < s.data + s.count {
        utf32 := one_utf32_char(t);

        latin := is_latin(utf32);

        use_latin_font_for_this_character := false;

        glyph: *Glyph_Data;

        /* Temporarily disabled; re-enable when we want international support.

        if (latin && use_other_font_for_latin_always) {
            if (latin_font.num_temporary_glyphs) {
                if utf32 == 32 {
                    // If it's the space at the end of Latin characters, don't do it!
                    // Umm, we don't try to look through multiple trailing spaces right now.
                    char *t = (char *)unicode.next_character((UTF8s *)s);
                    unsigned long next = one_utf32_char(t);
                    if is_latin(next) use_latin_font_for_this_character = true;
                } else {
                    // We already have a run of Latin characters, so let's do it.
                    use_latin_font_for_this_character = true;
                }
            } else {
                // Can only start a run of Latin characters with alphanumerics or quotes, for now.
                // The reason is that e.g. Chinese wants to use ? and ! in its own formatting.
                if ((utf32 >= 'A') && (utf32 <= 'Z')) use_latin_font_for_this_character = 1;
                if ((utf32 >= 'a') && (utf32 <= 'z')) use_latin_font_for_this_character = 1;
                if ((utf32 >= '0') && (utf32 <= '9')) use_latin_font_for_this_character = 1;
                if (utf32 == '\'') use_latin_font_for_this_character = 1;
                if (utf32 == '\"') use_latin_font_for_this_character = 1;
            }
        }
        */

        if use_latin_font_for_this_character {
            glyph = find_or_create_glyph_utf8(latin_font, t);
            add_glyph_to_temporaries(latin_font, glyph);

            // We put the glyph into the latin_font, then null it out so that
            // we don't put it into our own buffer.  The reason is that we want
            // the Latin font to apply font effects / substitutions / etc by
            // its own means, and then copy the results of that into our buffer.
            // If we were to copy it now, it'd be too soon.

            glyph = null;
        } else {
            if latin_font flush_my_latin_font(font, effect_flags);
            glyph = find_or_create_glyph_utf8(font, t);
        }


        if glyph {
            add_glyph_to_temporaries(font, glyph);

            if !latin all_latin = false;
        }

        t = unicode_next_character(t);
    }

    if latin_font && all_latin && !use_other_font_for_latin_always {
        //
        // Whoops!  Instead, let's use the latin font's glyphs.
        //

        convert_to_temporary_glyphs(latin_font, original_string, effect_flags);
        temporary_glyphs.count = 0;
        flush_my_latin_font(font, effect_flags);

        return;
    }

    if effect_flags do_glyph_substitutions(font, effect_flags);

    // If we had Latin characters at the end of e.g. Chinese, we need to flush.
    if (latin_font) flush_my_latin_font(font, effect_flags);
}


/*
*/
//
// @Cutnpaste from utf8 version!  Very hairy if we ever need to change this, which we probably will!
// Probably the utf8 version should convert to utf32 and call in.
//
convert_to_temporary_glyphs :: (using font: *Dynamic_Font, s: *int, effect_flags: u32) { // XXX Array parameter
    glyph_conversion_failed = false;

    temporary_glyphs.count = 0;
    if (latin_font) latin_font.temporary_glyphs.count = 0;

    if (!s) return;

    original_string := s;
    sum : int = 0;

    temporary_glyphs_width_in_pixels = 0;

    all_latin := true;
    if ! << original_string all_latin = false;  // Don't bother xreffing to latin font if the string is empty.

    while << s {
        utf32 := << cast(*u32) s;
        latin := is_latin(utf32);

        use_latin_font_for_this_character := false;

        glyph: *Glyph_Data;

        /* @Temporary: Disabled until we do international support.
        if (latin && use_other_font_for_latin_always) {
            if (latin_font.num_temporary_glyphs) {
                if (utf32 == ' ') {
                    // If it's the space at the end of Latin characters, don't do it!
                    // Umm, we don't try to look through multiple trailing spaces right now.
                    unsigned long next = *(s + 1);
                    if (is_latin(next)) use_latin_font_for_this_character = 1;
                } else {
                    // We already have a run of Latin characters, so let's do it.
                    use_latin_font_for_this_character = 1;
                }
            } else {
                // Can only start a run of Latin characters with alphanumerics or quotes, for now.
                // The reason is that e.g. Chinese wants to use ? and ! in its own formatting.
                if ((utf32 >= 'A') && (utf32 <= 'Z')) use_latin_font_for_this_character = 1;
                if ((utf32 >= 'a') && (utf32 <= 'z')) use_latin_font_for_this_character = 1;
                if ((utf32 >= '0') && (utf32 <= '9')) use_latin_font_for_this_character = 1;
                if (utf32 == '\'') use_latin_font_for_this_character = 1;
                if (utf32 == '\"') use_latin_font_for_this_character = 1;
            }
        }
        */

        if use_latin_font_for_this_character {
            glyph = find_or_create_glyph(latin_font, utf32);
            add_glyph_to_temporaries(latin_font, glyph);

            // We put the glyph into the latin_font, then null it out so that
            // we don't put it into our own buffer.  The reason is that we want
            // the Latin font to apply font effects / substitutions / etc by
            // its own means, and then copy the results of that into our buffer.
            // If we were to copy it now, it'd be too soon.

            glyph = null;
        } else {
            if latin_font flush_my_latin_font(font, effect_flags);

            glyph = find_or_create_glyph(font, utf32);
        }


        if glyph {
            add_glyph_to_temporaries(font, glyph);

            if !latin all_latin = false;
        }

        s += 1;
    }

    if latin_font && all_latin && !use_other_font_for_latin_always {
        //
        // Whoops!  Instead, let's use the latin font's glyphs.
        //

        convert_to_temporary_glyphs(latin_font, original_string, effect_flags);
        temporary_glyphs.count = 0;
        flush_my_latin_font(font, effect_flags);

        return;
    }

    if effect_flags do_glyph_substitutions(font, effect_flags);


    // temporary_glyphs[num_temporary_glyphs] = zero_glyph;  // Not doing the zero_glyph thing any more.
    // num_temporary_glyphs does not include the trailing zero, so we did not increment it.


    // If we had Latin characters at the end of e.g. Chinese, we need to flush.
    if latin_font flush_my_latin_font(font, effect_flags);
}


do_glyph_substitutions :: (using font : *Dynamic_Font, effect_flags: u32) {
    if effect_flags & FONT_EFFECT_LINING_FIGURES {
        // Substitute lining figures...
        for * ptr : temporary_glyphs {
            glyph := << ptr;
            << ptr = single_substitute(font, feature_lining_numbers, glyph);
        }
    }    

    if effect_flags & FONT_EFFECT_SMALLCAPS {
        // Substitute smallcaps...
        for * ptr : temporary_glyphs {
            // @Hack for Karmina; if we have LINING_FIGURES and SMALLCAPS selected,
            // then just do lining figures if it's a digit... otherwise we end
            // up converting digits to smallcaps and that doesn't look right.

            glyph := << ptr;
            if effect_flags & FONT_EFFECT_LINING_FIGURES {
                utf32 := glyph.utf32;
                if ((utf32 < 127) && isdigit(utf32)) continue;
            }

            << ptr = single_substitute(font, feature_smallcaps, glyph);
        }
    }    
}


// @Refactor: Didn't our add_glyph_to_temporaries just compute this width anyway? Why are we doing it again?
get_string_width_in_pixels :: (using font: *Dynamic_Font, s: string, effect_flags: u32) -> s64 {
    convert_to_temporary_glyphs(font, s, effect_flags);  // XXX Overload

    sum : s64 = 0;
    for temporary_glyphs 
        sum += get_glyph_width_in_pixels(it);

    return sum;
}

get_string_width_in_pixels2 :: (using font: *Dynamic_Font, s: *int, effect_flags: u32) -> s64 {     // XXX Overload
    convert_to_temporary_glyphs(font, s, effect_flags);

    sum : s64 = 0;
    for temporary_glyphs
        sum += get_glyph_width_in_pixels(it);

    return sum;
}

/*
get_string_width_in_pixels3 :: (using font: *Dynamic_Font, i0: int, i1: int) -> s64 {  // XXX Overload
    assert(i0 < temporary_glyphs.count);
    assert(i1 <= temporary_glyphs.count);

    sum: s64;
    for i0..i1-1 {
        sum += get_glyph_width_in_pixels(temporary_glyphs[it]);
    }

    return sum;
}
*/

read4_from_offset :: inline (base: *u8, offset: s64, reversed: bool) -> u32 {
    ptr := cast(*u32) (base + offset);
    
    if reversed {
        return my_swap4(<< ptr);
    } else {
        return << ptr;
    }
}

read2_from_offset :: inline (base: *u8, offset: s64, reversed: bool) -> u16 {
    ptr := cast(*u16) (base + offset);
    
    if reversed {
        return my_swap2(<< ptr);
    } else {
        return << ptr;
    }
}

find_feature :: (using font: *Dynamic_Font, feature_label: string) -> *Font_Feature {
    s0 : u32 = feature_label[0];
    s1 : u32 = feature_label[1];
    s2 : u32 = feature_label[2];
    s3 : u32 = feature_label[3];
    
    tag := s3 | (s2 << 8) | (s1 << 16) | (s0 << 24);

    for * features  if it.feature_tag == tag return it;

    return null;
}

read_coverage_table :: (coverage_table: *u8, reversed: bool) -> *Font_Coverage_Table {
    format := read2_from_offset(coverage_table, 0, reversed);

    result := new Font_Coverage_Table;
    result.format = format;

    if format == 1 {
        num_glyphs := read2_from_offset(coverage_table, 2, reversed);

        glyphs := new [num_glyphs] u16;
        if !glyphs.data return null;

        for 0..num_glyphs-1 {
            glyphs[it] = read2_from_offset(coverage_table + 4, xx it * 2, reversed);
        }

        result.glyphs = glyphs;
    } else if format == 2 {
        num_records := read2_from_offset(coverage_table, 2, reversed);
        result.range_records = new [num_records] Font_Range_Record;
        
        for * result.range_records {
            i := it_index;

            it.start = read2_from_offset(coverage_table, 4 + i * 6, reversed);
            it.end = read2_from_offset(coverage_table, 6 + i * 6, reversed);
            it.start_coverage_index = read2_from_offset(coverage_table, 8 + i * 6, reversed);
        }
    }
    
    return result;
}

read_sequence_table_entry :: (result: *Font_Sequence_Table_Entry, sequence_table: *u8, reversed: bool) {
    num_glyphs := read2_from_offset(sequence_table, 0, reversed);

    result.glyphs = new [num_glyphs] u16;
    if !result.glyphs.data return;

    for 0..num_glyphs-1
        result.glyphs[it] = read2_from_offset(sequence_table + 2, cast(s64) it * 2, reversed);
}

expand_feature :: (using font: *Dynamic_Font, feature: *Font_Feature, lookup_list_table: *u8) {
    if !feature return;
    if feature.expanded return;

    feature.expanded = true;

    table := feature.feature_tables_pointer;

    params_offset := read2_from_offset(table, 0, reversed);

    num_lookup_lists : s64 = read2_from_offset(table, 2, reversed);

    feature.lookup_lists = new [num_lookup_lists] u16;

    for 0..num_lookup_lists-1 {
        index := 4 + it * 2;
        feature.lookup_lists[it] = read2_from_offset(table, index, reversed);
    }

    feature.lookup_tables = new [num_lookup_lists] Font_Lookup_Table;

    //
    // Lookup tables...
    //

    num_lookups_max := read2_from_offset(lookup_list_table, 0, reversed);

    for 0..num_lookup_lists-1 {
        dest := *feature.lookup_tables[it];
        list_index := feature.lookup_lists[it];

        assert(list_index < num_lookups_max);

        offset := read2_from_offset(lookup_list_table + 2, 2 * list_index, reversed);

        table := lookup_list_table + offset;

        lookup_type    := read2_from_offset(table, 0, reversed);
        lookup_flags   := read2_from_offset(table, 2, reversed);
        subtable_count := read2_from_offset(table, 4, reversed);

        dest.lookup_type   = lookup_type;
        dest.lookup_flags  = lookup_flags;

        dest.subtables = new [subtable_count] Font_Lookup_Subtable;

        for * sub_dest : dest.subtables {
            subtable_offset := read2_from_offset(table, 6 + it_index * 2, reversed);

            subtable   := table + subtable_offset;
            table_type := read2_from_offset(subtable, 0, reversed);
            sub_dest.format = table_type;

            if lookup_type == 1 {  // Single Substitution Table
                coverage_offset := read2_from_offset(subtable, 2, reversed);
                coverage_table := subtable + coverage_offset;
                sub_dest.coverage_table = read_coverage_table(coverage_table, reversed);

                if table_type == 1 {  // SingleSubstFormat1
                    sub_dest.delta_glyph_id = read2_from_offset(subtable, 4, reversed);
                } else if table_type == 2 { // SingleSubstFormat2

                    count : s64 = read2_from_offset(subtable, 4, reversed);
                    sub_dest.glyphs = new [count] u16;

                    for * sub_dest.glyphs {
                         << it = read2_from_offset(subtable, 6 + 2 * it_index, reversed);
                    }
                } else {
                    assert(false);
                }
            } else if lookup_type == 2 {  // Multiple Substitution Table
                coverage_offset := read2_from_offset(subtable, 2, reversed);
                sequence_count := read2_from_offset(subtable, 4, reversed);
                coverage_table := subtable + coverage_offset;

                sub_dest.coverage_table = read_coverage_table(coverage_table, reversed);
                sub_dest.sequence_table = new [sequence_count] Font_Sequence_Table_Entry;

                for j : 0..sequence_count-1 {
                    sequence_offset := read2_from_offset(subtable + 6, cast(s64) j * 2, reversed);
                    sequence_table := subtable + sequence_offset;
                    read_sequence_table_entry(*sub_dest.sequence_table[j], sequence_table, reversed);
                }
            }
        }

        break;
    }
}

load_font :: (path: string, basename: string, pixel_height: int) -> (font: *Dynamic_Font, bytes_loaded: int) {
    ensure_fonts_are_initted();

    result := new Dynamic_Font;
    init_font(result);
    result.name = copy_string(basename);  // A waste?

    font_name := sprint("%1/%2", path, basename);
    defer free(font_name.data);

    loaded_font := find_loaded_font(font_name);
    bytes_loaded: s64 = 0;

    if !loaded_font {
        loaded_font, bytes_loaded = make_loaded_font(font_name);

        if !loaded_font {
            assert(false);
            return null, 0;
        }
    }

    face := loaded_font.face;
    result.private1 = face;
    result.character_height = pixel_height;
    result.default_line_spacing = face.height >> 6;

    e := FT_Select_Charmap(face, FT_ENCODING_UNICODE);

    font := result;
    font.name = copy_string(basename);

    while 1 {
        length : u32 = 0;
        tag := cast(FT_Sfnt_Tag) TTAG_GSUB;

        error := FT_Load_Sfnt_Table(face, tag, 0, null, *length);
        if error break;

        buffer : *u8 = alloc(length);
        if !buffer break;
        defer free(buffer);

        error = FT_Load_Sfnt_Table(face, tag, 0, buffer, *length);
        if (error) break;

        reversed := false;
        value := read4_from_offset(buffer, 0, reversed);

        if value == 0x00000100 {
            reversed = true;
        } else if value != 0x00010000 {
            break;
        }

        result.reversed = reversed;

        script_offset  := read2_from_offset(buffer, 4, reversed);
        feature_offset := read2_from_offset(buffer, 6, reversed);
        lookup_offset  := read2_from_offset(buffer, 8, reversed);


        //
        // Feature tables...
        //

        feature_list_table := buffer + feature_offset;
        num_feature_tables := read2_from_offset(feature_list_table, 0, reversed);

        {
            for 0..num_feature_tables-1 {
                dest : Font_Feature;
                dest.feature_tag = read4_from_offset(feature_list_table, 2 + xx it * 6, reversed);
                offset := read2_from_offset(feature_list_table, 6 + xx it * 6, reversed);
                dest.feature_tables_pointer = feature_list_table + offset;

                array_add(*font.features, dest);
            }
        }


        lookup_list_table := buffer + lookup_offset;

        font.feature_smallcaps = find_feature(font, "smcp");
//        font.feature_ligatures = find_feature(font, "liga");
        font.feature_lining_numbers = find_feature(font, "lnum");

        feature_gpos := find_feature(font, "gpos");

        expand_feature(font, font.feature_smallcaps, lookup_list_table);
        expand_feature(font, font.feature_lining_numbers, lookup_list_table);
//        font.expand_feature(font.feature_ligatures, lookup_list_table);

        break;
    }
/*
    void *gsub_table = FT_Get_Sfnt_Table(face, (FT_Sfnt_Tag)TTAG_GSUB);
    if (gsub_table) {
        int k = 1;
    }
*/
    array_add(*dynamic_fonts, result);

    return result, bytes_loaded;
}

get_font_at_size :: (path: string, name: string, pixel_height: int) -> *Dynamic_Font {
    for dynamic_fonts {
        if (it.character_height != pixel_height) continue;
        if (it.name != name) continue;

        return it;
    }

    result := load_font(path, name, pixel_height);
    
//    void app_postprocess_font(font: *Dynamic_Font);
//    app_postprocess_font(result);

    return result;
}

get_baseline_height :: (font: *Dynamic_Font) -> s64 {
    return font.character_height / 4;
}


//
// draw_quad2 is specifically for text only (v-flip is gone):
//
draw_quad2 :: (p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2,
               uv0: Vector2, uv1: Vector2, uv2: Vector2, uv3: Vector2,
               color: Vector4) {
    z := 0.0;

    // @TODO: Texture coordinates here are flipped because
    // the textures are loaded right-handed. Sigh.

    glTexCoord2f(uv0.x, uv0.y);
    glColor4f(color.x, color.y, color.z, color.w);
    glVertex3f(p0.x, p0.y, z);
    glTexCoord2f(uv1.x, uv1.y);
    glVertex3f(p1.x, p1.y, z);
    glTexCoord2f(uv2.x, uv2.y);
    glVertex3f(p2.x, p2.y, z);

    glTexCoord2f(uv0.x, uv0.y);
    glVertex3f(p0.x, p0.y, z);
    glTexCoord2f(uv2.x, uv2.y);
    glVertex3f(p2.x, p2.y, z);
    glTexCoord2f(uv3.x, uv3.y);
    glVertex3f(p3.x, p3.y, z);
}



//
// Stuff that might better be in the client. Maybe we should factor add_letter_quad
// so that there is a very small part-that-draws...
//

add_letter_quad :: (font: *Dynamic_Font, info: *Glyph_Data, 
                    sx1: float, sx2: float,
                    sy1: float, sy2: float,
                    color: Vector4) {

    // @Robustness: These assume our coordinates are in screenspace...
    if sx2 < 0 return;
    if sx1 > cast(float) my_back_buffer_width return;
    if sy2 < 0 return;
    if sy1 > cast(float) my_back_buffer_height return;

    page := info.page;
    
    // @Speed
    if page.bitmap_data.width <= 1 return;
    if page.bitmap_data.height <= 1 return;

    w := cast(float) page.bitmap_data.width;
    h := cast(float) page.bitmap_data.height;

    aa := info.x0;
    u0 := cast(float) info.x0 / w;
    u1 := cast(float) (info.x0 + info.width) / w;
    v0 := cast(float) info.y0 / h;
    v1 := cast(float) (info.y0 + info.height) / h;

    iw := 1.0 / cast(float) my_back_buffer_width;
    sx1 *= iw;
    sx2 *= iw;
    sy1 *= iw;
    sy2 *= iw;

    p0 := make_vector2(sx1, sy1);
    p1 := make_vector2(sx2, sy1);
    p2 := make_vector2(sx2, sy2);
    p3 := make_vector2(sx1, sy2);

    uv0 := make_vector2(u0, v0);
    uv1 := make_vector2(u1, v0);
    uv2 := make_vector2(u1, v1);
    uv3 := make_vector2(u0, v1);

    draw_quad2(p0, p1, p2, p3, 
               uv0, uv1, uv2, uv3,
               color);
}

draw_temporary_glyphs :: (font: *Dynamic_Font, n0: s64, n1: s64,
                          x: s64, y: s64,
                          color: Vector4, effect_flags: u32) {
    if n1 < n0 return;

    assert(n0 >= 0);
    assert(n1 >= 0);
    assert(n0 < font.temporary_glyphs.count);
    assert(n1 < font.temporary_glyphs.count);

    maybe_offset := false;
    if font.y_offset_for_my_latin_characters maybe_offset = true;

    sx := cast(float) x;
    sy := cast(float) y;

    kerning_offset := make_vector2(0, 0);
//    do_kerning := globals_do_kerning && !(effect_flags & FONT_EFFECT_NO_KERNING);
    do_kerning := !(effect_flags & FONT_EFFECT_NO_KERNING);

    if do_kerning prepare_for_kerning(font);


    glTexParameterf(_GL_TEXTURE_2D, _GL_TEXTURE_MAX_ANISOTROPY_EXT, 0);
    
    glTexParameteri(_GL_TEXTURE_2D, _GL_TEXTURE_MIN_FILTER, _GL_NEAREST);
    glTexParameteri(_GL_TEXTURE_2D, _GL_TEXTURE_MAG_FILTER, _GL_NEAREST);


    last_texture: s64 = -1;

    for i: n0..n1 {
        info := font.temporary_glyphs[i];

        if !info.page continue;
        map := info.page.map;
        if !map continue;
        
        if info.page.dirty {
            info.page.dirty = false;
            update_texture(map);
        }

        if map.id != last_texture {
            last_texture = map.id;
            //if i != n0 glEnd();
            glBindTexture(_GL_TEXTURE_2D, map.id);
            //if i != n0 glBegin(_GL_TRIANGLES);
        }

/*
        if i && do_kerning {
            prior := font.temporary_glyphs[i-1];
            get_kerning(font, prior, info, *kerning_offset);
            sx += kerning_offset.x;
        }
*/

        sx1 := sx  + cast(float) info.offset_x;
        sx2 := sx1 + cast(float) info.width;

        sy2 := sy  + cast(float) info.ascent + kerning_offset.y;
        sy1 := sy2 - cast(float) info.height;

        if maybe_offset && is_latin(info.utf32) {
            // e.g. our Chinese font did not seem to make characters
            // line up properly.
            sy1 += font.y_offset_for_my_latin_characters;
            sy2 += font.y_offset_for_my_latin_characters;
        }

        glBegin(_GL_TRIANGLES);
        add_letter_quad(font, info, 
                        sx1, sx2, sy1, sy2, color);
        glEnd();

		sx += cast(float) info.advance;
    }
}

draw_text :: (font: *Dynamic_Font, x: s64, y: s64,
              color: Vector4, text: string, effect_flags: u32) {

    convert_to_temporary_glyphs(font, text, effect_flags);

//    glBegin(_GL_TRIANGLES);
    draw_temporary_glyphs(font, 0, font.temporary_glyphs.count - 1,
                          x, y, 
                          color, effect_flags);
//    glEnd();

}
