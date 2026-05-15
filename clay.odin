package clay

import "core:simd"
import "base:runtime"
import "base:intrinsics"
import "core:mem"

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC TYPES
// ─────────────────────────────────────────────────────────────────────────────

// Opaque context handle – definition below.
Clay_Context :: struct{}

// Memory arena used by Clay for all internal allocations.
Clay_Arena :: struct {
    next_allocation: uintptr,
    capacity:        uint,
    memory:          [^]u8,
}

Clay_Dimensions :: [2]f32
Clay_Vector2    ::  [2]f32
// Colors are conventionally 0-255 but interpretation is up to the renderer.
Clay_Color      :: [4]u8
Clay_Bounding_Box :: [4]f32

Clay_Element_Id :: struct {
    id:        u32, // Hash result
    offset:    u32,
    base_id:   u32,
    string_id: string,
}

Clay_Corner_Radius :: struct {
    top_left, top_right, bottom_left, bottom_right: f32,
}

// ── Layout Enums ──────────────────────────────────────────────────────────────

Clay_Layout_Direction :: enum u8 {
    Left_To_Right = 0,
    Top_To_Bottom,
}

Clay_Layout_Alignment_X :: enum u8 {
    Left = 0,
    Right,
    Center,
}

Clay_Layout_Alignment_Y :: enum u8 {
    Top = 0,
    Bottom,
    Center,
}

Clay_Sizing_Type :: enum u8 {
    Fit     = 0, // Wraps tightly to contents
    Grow,        // Expands to fill available space
    Percent,     // 0-1 fraction of parent
    Fixed,       // Exact pixel size
}

// ── Layout Config ─────────────────────────────────────────────────────────────

Clay_Child_Alignment :: struct {
    x: Clay_Layout_Alignment_X,
    y: Clay_Layout_Alignment_Y,
}

Clay_Sizing_Min_Max :: struct { min, max: f32 }

Clay_Sizing_Axis_Size :: struct #raw_union {
    min_max: Clay_Sizing_Min_Max,
    percent: f32,
}

Clay_Sizing_Axis :: struct {
    size: Clay_Sizing_Axis_Size,
    type: Clay_Sizing_Type,
}

Clay_Sizing :: struct {
    width:  Clay_Sizing_Axis,
    height: Clay_Sizing_Axis,
}

Clay_Padding :: struct { left, right, top, bottom: u16 }

Clay_Layout_Config :: struct {
    sizing:           Clay_Sizing,
    padding:          Clay_Padding,
    child_gap:        u16,
    child_alignment:  Clay_Child_Alignment,
    layout_direction: Clay_Layout_Direction,
}

// ── Text Element Config ───────────────────────────────────────────────────────

Clay_Text_Wrap_Mode :: enum u8 {
    Words    = 0, // Break on whitespace
    Newlines,     // Break only on newlines
    None,         // No wrapping
}

Clay_Text_Alignment :: enum u8 {
    Left   = 0,
    Center,
    Right,
}

Clay_Text_Element_Config :: struct {
    user_data:      rawptr,
    text_color:     Clay_Color,
    font_id:        u16,
    font_size:      u16,
    letter_spacing: u16,
    line_height:    u16,
    wrap_mode:      Clay_Text_Wrap_Mode,
    text_alignment: Clay_Text_Alignment,
}

// ── Element Configs ───────────────────────────────────────────────────────────

Clay_Aspect_Ratio_Element_Config :: struct {
    aspect_ratio: f32,
}

Clay_Image_Element_Config :: struct {
    image_data: rawptr,
}

Clay_Floating_Attach_Point_Type :: enum u8 {
    Left_Top      = 0,
    Left_Center,
    Left_Bottom,
    Center_Top,
    Center_Center,
    Center_Bottom,
    Right_Top,
    Right_Center,
    Right_Bottom,
}

Clay_Floating_Attach_Points :: struct {
    element: Clay_Floating_Attach_Point_Type,
    parent:  Clay_Floating_Attach_Point_Type,
}

Clay_Pointer_Capture_Mode :: enum u8 {
    Capture     = 0,
    Passthrough,
}

Clay_Floating_Attach_To :: enum u8 {
    None              = 0,
    Parent,
    Element_With_Id,
    Root,
}

Clay_Floating_Clip_To :: enum u8 {
    None            = 0,
    Attached_Parent,
}

Clay_Floating_Element_Config :: struct {
    offset:               Clay_Vector2,
    expand:               Clay_Dimensions,
    parent_id:            u32,
    z_index:              i16,
    attach_points:        Clay_Floating_Attach_Points,
    pointer_capture_mode: Clay_Pointer_Capture_Mode,
    attach_to:            Clay_Floating_Attach_To,
    clip_to:              Clay_Floating_Clip_To,
}

Clay_Custom_Element_Config :: struct {
    custom_data: rawptr,
}

Clay_Clip_Element_Config :: struct {
    horizontal:   bool,
    vertical:     bool,
    child_offset: Clay_Vector2,
}

Clay_Border_Width :: struct {
    left, right, top, bottom, between_children: u16,
}

Clay_Border_Element_Config :: struct {
    color: Clay_Color,
    width: Clay_Border_Width,
}

// ── Render Data Types ─────────────────────────────────────────────────────────

Clay_Text_Render_Data :: struct {
    string_contents: string,
    text_color:      Clay_Color,
    font_id:         u16,
    font_size:       u16,
    letter_spacing:  u16,
    line_height:     u16,
}

Clay_Rectangle_Render_Data :: struct {
    background_color: Clay_Color,
    corner_radius:    Clay_Corner_Radius,
}

Clay_Image_Render_Data :: struct {
    background_color: Clay_Color,
    corner_radius:    Clay_Corner_Radius,
    image_data:       rawptr,
}

Clay_Custom_Render_Data :: struct {
    background_color: Clay_Color,
    corner_radius:    Clay_Corner_Radius,
    custom_data:      rawptr,
}

Clay_Clip_Render_Data :: struct {
    horizontal: bool,
    vertical:   bool,
}

Clay_Border_Render_Data :: struct {
    color:         Clay_Color,
    corner_radius: Clay_Corner_Radius,
    width:         Clay_Border_Width,
}

Clay_Render_Data :: struct #raw_union {
    rectangle: Clay_Rectangle_Render_Data,
    text:      Clay_Text_Render_Data,
    image:     Clay_Image_Render_Data,
    custom:    Clay_Custom_Render_Data,
    border:    Clay_Border_Render_Data,
    clip:      Clay_Clip_Render_Data,
}

// ── Render Command ────────────────────────────────────────────────────────────

Clay_Render_Command_Type :: enum u8 {
    None         = 0,
    Rectangle,
    Border,
    Text,
    Image,
    Scissor_Start,
    Scissor_End,
    Custom,
}

Clay_Render_Command :: struct {
    bounding_box: Clay_Bounding_Box,
    render_data:  Clay_Render_Data,
    user_data:    rawptr,
    id:           u32,
    z_index:      i16,
    command_type: Clay_Render_Command_Type,
}

// ── Pointer / Interaction ─────────────────────────────────────────────────────

Clay_Pointer_Data_Interaction_State :: enum u8 {
    Pressed_This_Frame  = 0,
    Pressed,
    Released_This_Frame,
    Released,
}

Clay_Pointer_Data :: struct {
    position: Clay_Vector2,
    state:    Clay_Pointer_Data_Interaction_State,
}

// ── Element Declaration ───────────────────────────────────────────────────────

Clay_Element_Declaration :: struct {
    id:               Clay_Element_Id,
    layout:           Clay_Layout_Config,
    background_color: Clay_Color,
    corner_radius:    Clay_Corner_Radius,
    aspect_ratio:     Clay_Aspect_Ratio_Element_Config,
    image:            Clay_Image_Element_Config,
    floating:         Clay_Floating_Element_Config,
    custom:           Clay_Custom_Element_Config,
    clip:             Clay_Clip_Element_Config,
    border:           Clay_Border_Element_Config,
    user_data:        rawptr,
}

// ── Misc Public Structs ───────────────────────────────────────────────────────

Clay_Scroll_Container_Data :: struct {
    scroll_position:              ^Clay_Vector2,
    scroll_container_dimensions:  Clay_Dimensions,
    content_dimensions:           Clay_Dimensions,
    config:                       Clay_Clip_Element_Config,
    found:                        bool,
}

Clay_Element_Data :: struct {
    bounding_box: Clay_Bounding_Box,
    found:        bool,
}

// ── Error Handling ────────────────────────────────────────────────────────────

Clay_Error_Type :: enum u8 {
    Text_Measurement_Function_Not_Provided = 0,
    Arena_Capacity_Exceeded,
    Elements_Capacity_Exceeded,
    Text_Measurement_Capacity_Exceeded,
    Duplicate_Id,
    Floating_Container_Parent_Not_Found,
    Percentage_Over_1,
    Internal_Error,
}

Clay_Error_Data :: struct {
    error_type: Clay_Error_Type,
    error_text: string,
    user_data:  rawptr,
}

Clay_Error_Handler :: struct {
    error_handler_function: proc(error_data: Clay_Error_Data),
    user_data:              rawptr,
}

_Clay_Warning :: struct {
    base_message:    string,
    dynamic_message: string,
}

_Clay_Shared_Element_Config :: struct {
    background_color: Clay_Color,
    corner_radius:    Clay_Corner_Radius,
    user_data:        rawptr,
}

_Clay_Element_Config_Type :: enum u8 {
    None    = 0,
    Border,
    Floating,
    Clip,
    Aspect,
    Image,
    Text,
    Custom,
    Shared,
}

_Clay_Element_Config_Union :: struct #raw_union {
    text_element_config:         ^Clay_Text_Element_Config,
    aspect_ratio_element_config: ^Clay_Aspect_Ratio_Element_Config,
    image_element_config:        ^Clay_Image_Element_Config,
    floating_element_config:     ^Clay_Floating_Element_Config,
    custom_element_config:       ^Clay_Custom_Element_Config,
    clip_element_config:         ^Clay_Clip_Element_Config,
    border_element_config:       ^Clay_Border_Element_Config,
    shared_element_config:       ^_Clay_Shared_Element_Config,
}

_Clay_Element_Config :: struct {
    type:   _Clay_Element_Config_Type,
    config: _Clay_Element_Config_Union,
}

_Clay_Wrapped_Text_Line :: struct {
    dimensions: Clay_Dimensions,
    line:       string,
}

_Clay_Text_Element_Data :: struct {
    text:                  string,
    preferred_dimensions:  Clay_Dimensions,
    element_index:         i32,
    wrapped_lines:         []_Clay_Wrapped_Text_Line
}

_Clay_Layout_Element_Content :: struct #raw_union {
    children:          []i32,
    text_element_data: ^_Clay_Text_Element_Data,
}

_Clay_Layout_Element :: struct {
    children_or_text_content: _Clay_Layout_Element_Content,
    dimensions:               Clay_Dimensions,
    min_dimensions:           Clay_Dimensions,
    layout_config:            ^Clay_Layout_Config,
    element_configs:          []_Clay_Element_Config,
    id:                       u32,
}

_Clay_Scroll_Container_Data_Internal :: struct {
    layout_element:       ^_Clay_Layout_Element,
    bounding_box:         Clay_Bounding_Box,
    content_size:         Clay_Dimensions,
    scroll_origin:        Clay_Vector2,
    pointer_origin:       Clay_Vector2,
    scroll_momentum:      Clay_Vector2,
    scroll_position:      Clay_Vector2,
    previous_delta:       Clay_Vector2,
    momentum_time:        f32,
    element_id:           u32,
    open_this_frame:      bool,
    pointer_scroll_active: bool,
}

_Clay_Debug_Element_Data :: struct {
    collision: bool,
    collapsed: bool,
}

_Clay_Layout_Element_Hash_Map_Item :: struct {
    bounding_box:             Clay_Bounding_Box,
    element_id:               Clay_Element_Id,
    layout_element:           ^_Clay_Layout_Element,
    on_hover_function:        proc(element_id: Clay_Element_Id, pointer_data: Clay_Pointer_Data, user_data: uintptr),
    hover_function_user_data: uintptr,
    next_index:               i32,
    generation:               u32,
    id_alias:                 u32,
    debug_data:               ^_Clay_Debug_Element_Data,
}

_Clay_Measured_Word :: struct {
    start_offset: i32,
    length:       i32,
    width:        f32,
    next:         i32,
}

_Clay_Measure_Text_Cache_Item :: struct {
    unwrapped_dimensions:        Clay_Dimensions,
    measured_words_start_index:  i32,
    min_width:                   f32,
    contains_newlines:           bool,
    id:                          u32,
    next_index:                  i32,
    generation:                  u32,
}

_Clay_Layout_Element_Tree_Node :: struct {
    layout_element:    ^_Clay_Layout_Element,
    position:          Clay_Vector2,
    next_child_offset: Clay_Vector2,
}

_Clay_Layout_Element_Tree_Root :: struct {
    layout_element_index: i32,
    parent_id:            u32,
    clip_element_id:      u32,
    z_index:              i16,
    pointer_offset:       Clay_Vector2,
}

_Clay_Context :: struct {
    max_element_count:                i32,
    max_measure_text_cache_word_count: i32,
    warnings_enabled:                 bool,
    error_handler:                    Clay_Error_Handler,
    text_measurement_function_not_set: bool,
    warnings:                         [dynamic]_Clay_Warning,

    pointer_info:                    Clay_Pointer_Data,
    layout_dimensions:               Clay_Dimensions,
    dynamic_element_index_base_hash: Clay_Element_Id,
    dynamic_element_index:           u32,
    debug_mode_enabled:              bool,
    disable_culling:                 bool,
    external_scroll_handling_enabled: bool,
    debug_selected_element_id:       u32,
    generation:                      u32,
    arena_reset_offset:              uint,
    measure_text_user_data:          rawptr,
    query_scroll_offset_user_data:   rawptr,
    internal_allocator:              runtime.Allocator,

    // Layout elements / render commands
    layout_elements:                  [dynamic]_Clay_Layout_Element,
    render_commands:                  [dynamic]Clay_Render_Command,
    open_layout_element_stack:        [dynamic]i32,
    layout_element_children:          [dynamic]i32,
    layout_element_children_buffer:   [dynamic]i32,
    text_element_data:                [dynamic]_Clay_Text_Element_Data,
    aspect_ratio_element_indexes:     [dynamic]i32,
    reusable_element_index_buffer:    [dynamic]i32,
    layout_element_clip_element_ids:  [dynamic]i32,

    // Configs
    layout_configs:               [dynamic]Clay_Layout_Config,
    element_configs:              [dynamic]_Clay_Element_Config,
    text_element_configs:         [dynamic]Clay_Text_Element_Config,
    aspect_ratio_element_configs: [dynamic]Clay_Aspect_Ratio_Element_Config,
    image_element_configs:        [dynamic]Clay_Image_Element_Config,
    floating_element_configs:     [dynamic]Clay_Floating_Element_Config,
    clip_element_configs:         [dynamic]Clay_Clip_Element_Config,
    custom_element_configs:       [dynamic]Clay_Custom_Element_Config,
    border_element_configs:       [dynamic]Clay_Border_Element_Config,
    shared_element_configs:       [dynamic]_Clay_Shared_Element_Config,

    // Misc data structures
    layout_element_id_strings:       [dynamic]string,
    wrapped_text_lines:              [dynamic]_Clay_Wrapped_Text_Line,
    layout_element_tree_node_array1: [dynamic]_Clay_Layout_Element_Tree_Node,
    layout_element_tree_roots:       [dynamic]_Clay_Layout_Element_Tree_Root,
    layout_elements_hash_map_internal: [dynamic]_Clay_Layout_Element_Hash_Map_Item,
    layout_elements_hash_map:        [dynamic]i32,
    measure_text_hash_map_internal:  [dynamic]_Clay_Measure_Text_Cache_Item,
    measure_text_hash_map_internal_free_list: [dynamic]i32,
    measure_text_hash_map:           [dynamic]i32,
    measured_words:                  [dynamic]_Clay_Measured_Word,
    measured_words_free_list:        [dynamic]i32,
    open_clip_element_stack:         [dynamic]i32,
    pointer_over_ids:                [dynamic]Clay_Element_Id,
    scroll_container_datas:          [dynamic]_Clay_Scroll_Container_Data_Internal,
    tree_node_visited:               [dynamic]bool,
    dynamic_string_data:             [dynamic]u8,
    debug_element_data:              [dynamic]_Clay_Debug_Element_Data,
}

@(private) _clay_current_context: ^_Clay_Context
@(private) _clay_measure_text_fn: proc(text: string, config: ^Clay_Text_Element_Config, user_data: rawptr) -> Clay_Dimensions
@(private) _clay_query_scroll_offset_fn: proc(element_id: u32, user_data: rawptr) -> Clay_Vector2

// Debug view constants
@(private) _CLAY_DEBUGVIEW_COLOR_1          :Clay_Color : {58, 56, 52, 255}
@(private) _CLAY_DEBUGVIEW_COLOR_2          :Clay_Color : {62, 60, 58, 255}
@(private) _CLAY_DEBUGVIEW_COLOR_3          :Clay_Color : {141, 133, 135, 255}
@(private) _CLAY_DEBUGVIEW_COLOR_4          :Clay_Color : {238, 226, 231, 255}
@(private) _CLAY_DEBUGVIEW_COLOR_SELECTED_ROW :Clay_Color : {102, 80, 78, 255}
@(private) _CLAY_DEBUGVIEW_ROW_HEIGHT       :: 30
@(private) _CLAY_DEBUGVIEW_OUTER_PADDING    :: 10
@(private) _CLAY_DEBUGVIEW_INDENT_WIDTH     :: 16

_clay_debug_view_width:: 400
_clay_debug_view_highlight_color:Clay_Color : {168, 66, 28, 100}

// Default constant values
@(private) _CLAY_EPSILON:: 0.01
@(private) _CLAY_MAXFLOAT:: max(f32)

// Default layout config (all zero/false)
CLAY_LAYOUT_DEFAULT: Clay_Layout_Config

// ─────────────────────────────────────────────────────────────────────────────
// DEFAULTS / ZERO VALUES (returned on out-of-bounds access)
// ─────────────────────────────────────────────────────────────────────────────

@(private) _layout_config_default:               Clay_Layout_Config
@(private) _text_element_config_default:         Clay_Text_Element_Config
@(private) _aspect_ratio_element_config_default: Clay_Aspect_Ratio_Element_Config
@(private) _image_element_config_default:        Clay_Image_Element_Config
@(private) _floating_element_config_default:     Clay_Floating_Element_Config
@(private) _clip_element_config_default:         Clay_Clip_Element_Config
@(private) _custom_element_config_default:       Clay_Custom_Element_Config
@(private) _border_element_config_default:       Clay_Border_Element_Config
@(private) _shared_element_config_default:       _Clay_Shared_Element_Config
@(private) _element_config_default:              _Clay_Element_Config
@(private) _layout_element_default:              _Clay_Layout_Element
@(private) _render_command_default:              Clay_Render_Command
@(private) _element_id_default:                 Clay_Element_Id
@(private) _warning_default:                    _Clay_Warning
@(private) _scroll_container_data_internal_default: _Clay_Scroll_Container_Data_Internal
@(private) _layout_element_hash_map_item_default: _Clay_Layout_Element_Hash_Map_Item
@(private) _measured_word_default:              _Clay_Measured_Word
@(private) _measure_text_cache_item_default:    _Clay_Measure_Text_Cache_Item
@(private) _layout_element_tree_node_default:   _Clay_Layout_Element_Tree_Node
@(private) _layout_element_tree_root_default:   _Clay_Layout_Element_Tree_Root
@(private) _debug_element_data_default:         _Clay_Debug_Element_Data
@(private) _bool_default:                       bool
@(private) _i32_default:                        i32
@(private) _u8_default:                         u8
@(private) _string_default:                     string
@(private) _wrapped_text_line_default:          _Clay_Wrapped_Text_Line
@(private) _text_element_data_default:          _Clay_Text_Element_Data

@(private)
_clay_error_handler_function_default :: proc(error_data: Clay_Error_Data) {
    // Default: no-op
}

@(private)
_clay_array_range_check :: proc(#any_int index: int, #any_int length: int) -> bool {
    if index < length && index >= 0 { return true }
    ctx := _clay_current_context
    if ctx != nil && ctx.error_handler.error_handler_function != nil {
        ctx.error_handler.error_handler_function(Clay_Error_Data{
            error_type = .Internal_Error,
            error_text = "Clay attempted to make an out of bounds array access. This is an internal error and is likely a bug.",
        })
    }
    return false
}

@(private)
_clay_array_get :: proc(arr: ^[dynamic]$T, #any_int index: int, default_val: ^T) -> ^T {
    if _clay_array_range_check(index, len(arr)) {
        return &arr[index]
    }
    return default_val
}

@(private)
_clay_array_get_value :: proc(arr: ^[dynamic]$T, #any_int index: int, default_val: T) -> T {
    if _clay_array_range_check(index, len(arr)) {
        return arr[index]
    }
    return default_val
}

@(private)
_clay_array_add :: proc(arr: ^[dynamic]$T, item: T) -> ^T {
    append(arr, item)
    return &arr[len(arr) - 1]
}

@(private)
_clay_array_set :: proc(arr: ^[dynamic]$T, #any_int index: int, value: T) {
    if index < len(arr) {
        arr[index] = value
    } else {
        append(arr, value)
    }
}

@(private)
_clay_array_remove_swapback :: proc(arr: ^[dynamic]$T, #any_int index: int, default_val: T) -> T {
    if _clay_array_range_check(index, len(arr)) {
        removed:= arr[index]
        unordered_remove(arr, index)
        return removed
    }
    return default_val
}

@(private)
_clay_array_slice_get :: proc(slice: []$T, #any_int index: int, default_val: ^T) -> ^T {
    if _clay_array_range_check(index, len(slice)) {
        return &slice[index]
    }
    return default_val
}

@(private)
_clay_mem_compare :: proc(a: rawptr, b: rawptr, #any_int length: int) -> bool {
    return mem.compare_ptrs(a, b, length) == 0
}

@(private)
_clay_float_equal :: proc(left, right: f32) -> bool {
    diff := left - right
    return diff < _CLAY_EPSILON && diff > -_CLAY_EPSILON
}

@(private)
_clay_get_current_context :: proc() -> ^_Clay_Context {
    return _clay_current_context
}

@(private)
_clay_get_open_layout_element :: proc() -> ^_Clay_Layout_Element {
    ctx := _clay_current_context
    index := _clay_array_get_value(&ctx.open_layout_element_stack, len(ctx.open_layout_element_stack) - 1, 0)
    return _clay_array_get(&ctx.layout_elements, index, &_layout_element_default)
}

@(private)
_clay_get_parent_element_id :: proc() -> u32 {
    ctx := _clay_current_context
    open_element := _clay_get_open_layout_element()
    return open_element.id
}

@(private)
_clay_store_text_element_config :: proc(config: Clay_Text_Element_Config) -> ^Clay_Text_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.text_element_configs, config)
}

@(private)
_clay_store_aspect_ratio_element_config :: proc(config: Clay_Aspect_Ratio_Element_Config) -> ^Clay_Aspect_Ratio_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.aspect_ratio_element_configs, config)
}

@(private)
_clay_store_image_element_config :: proc(config: Clay_Image_Element_Config) -> ^Clay_Image_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.image_element_configs, config)
}

@(private)
_clay_store_floating_element_config :: proc(config: Clay_Floating_Element_Config) -> ^Clay_Floating_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.floating_element_configs, config)
}

@(private)
_clay_store_custom_element_config :: proc(config: Clay_Custom_Element_Config) -> ^Clay_Custom_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.custom_element_configs, config)
}

@(private)
_clay_store_clip_element_config :: proc(config: Clay_Clip_Element_Config) -> ^Clay_Clip_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.clip_element_configs, config)
}

@(private)
_clay_store_border_element_config :: proc(config: Clay_Border_Element_Config) -> ^Clay_Border_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.border_element_configs, config)
}

@(private)
_clay_store_shared_element_config :: proc(config: _Clay_Shared_Element_Config) -> ^_Clay_Shared_Element_Config {
    ctx := _clay_current_context
    return _clay_array_add(&ctx.shared_element_configs, config)
}

// ── Hash functions ────────────────────────────────────────────────────────────

@(private)
_clay_hash_number :: proc(#any_int offset: u32, #any_int seed: u32) -> Clay_Element_Id {
    hash := seed
    hash ~= hash >> 17
    hash *= 0xbf85114f
    hash ~= hash >> 11
    hash += offset
    hash ~= hash << 4
    hash *= 0x27a56727
    hash ~= hash >> 11
    hash *= 0x81a84683
    return Clay_Element_Id{id = hash == 0 ? 1 : hash, offset = offset, base_id = seed}
}

@(private)
_clay_hash_string :: proc(key: string, offset: u32, seed: u32) -> Clay_Element_Id {
    hash: u32 = 0
    // FNV-like hash
    base := seed != 0 ? seed : 5381
    for i in 0..<len(key) {
        base = ((base << 5) + base) + u32(key[i])
    }
    hash = base + offset
    if hash == 0 { hash = 1 }
    return Clay_Element_Id{id = hash, offset = offset, base_id = seed, string_id = key}
}

// ── Element config attachment ─────────────────────────────────────────────────

@(private)
_clay_attach_element_config :: proc(config: _Clay_Element_Config_Union, type: _Clay_Element_Config_Type) -> _Clay_Element_Config {
    ctx := _clay_current_context
    open_element := _clay_get_open_layout_element()
    open_element.element_configs = open_element.element_configs[:len(open_element.element_configs) + 1]
    result := _Clay_Element_Config{type = type, config = config}
    _clay_array_add(&ctx.element_configs, result)
    return result
}

@(private)
_clay_find_element_config_with_type :: proc(element: ^_Clay_Layout_Element, type: _Clay_Element_Config_Type) -> _Clay_Element_Config_Union {
    for i in 0..< len(element.element_configs) {
        config := _clay_array_slice_get(element.element_configs, i, &_element_config_default)
        if config.type == type {
            return config.config
        }
    }
    return {}
}

@(private)
_clay_element_has_config :: proc(element: ^_Clay_Layout_Element, type: _Clay_Element_Config_Type) -> bool {
    for i in 0..< len(element.element_configs) {
        config := _clay_array_slice_get(element.element_configs, i, &_element_config_default)
        if config.type == type { return true }
    }
    return false
}

// ── Hash map ──────────────────────────────────────────────────────────────────

@(private)
_clay_add_hash_map_item :: proc(element_id: Clay_Element_Id, layout_element: ^_Clay_Layout_Element, id_alias: u32) -> ^_Clay_Layout_Element_Hash_Map_Item {
    ctx := _clay_current_context
    hash_map := &ctx.layout_elements_hash_map
    hash_map_internal := &ctx.layout_elements_hash_map_internal
    debug_data := _clay_array_get(&ctx.debug_element_data, len(hash_map_internal), &_debug_element_data_default)

    bucket_index := i32(element_id.id % u32(cap(hash_map)))
    existing_index := hash_map[bucket_index]
    if existing_index != -1 {
        // Walk chain
        item := _clay_array_get(hash_map_internal, existing_index, &_layout_element_hash_map_item_default)
        for item.id_alias != element_id.id && item.next_index != -1 {
            existing_index = item.next_index
            item = _clay_array_get(hash_map_internal, existing_index, &_layout_element_hash_map_item_default)
        }
        if item.element_id.id == element_id.id {
            // Duplicate
            if len(ctx.debug_element_data) > 0 && item.debug_data != nil {
                item.debug_data.collision = true
            }
            return item
        }
    }

    new_item := _Clay_Layout_Element_Hash_Map_Item{
        element_id     = element_id,
        layout_element = layout_element,
        next_index     = existing_index,
        generation     = ctx.generation + 1,
        id_alias       = id_alias,
        debug_data     = debug_data,
    }
    added := _clay_array_add(hash_map_internal, new_item)
    new_item_index := i32(len(hash_map_internal) - 1)
    hash_map[bucket_index] = new_item_index
    return added
}

@(private)
_clay_get_hash_map_item :: proc(id: u32) -> ^_Clay_Layout_Element_Hash_Map_Item {
    ctx := _clay_current_context
    hash_map := &ctx.layout_elements_hash_map
    hash_map_internal := &ctx.layout_elements_hash_map_internal
    bucket_index := i32(id % u32(cap(hash_map)))
    index := hash_map[bucket_index]
    for index != -1 {
        item := _clay_array_get(hash_map_internal, index, &_layout_element_hash_map_item_default)
        if item.element_id.id == id { return item }
        index = item.next_index
    }
    return &_layout_element_hash_map_item_default
}

@(private)
_clay_generate_id_for_anonymous_element :: proc(open_layout_element: ^_Clay_Layout_Element) -> Clay_Element_Id {
    ctx := _clay_current_context
    parent_element := _clay_array_get(&ctx.layout_elements,
        _clay_array_get_value(&ctx.open_layout_element_stack, len(ctx.open_layout_element_stack) - 2, 0), &_layout_element_default)
    element_id := _clay_hash_number(len(parent_element.children_or_text_content.children), parent_element.id)
    open_layout_element.id = element_id.id
    _clay_add_hash_map_item(element_id, open_layout_element, 0)
    _clay_array_set(&ctx.layout_element_id_strings, len(ctx.layout_elements) - 1, element_id.string_id)
    ctx.dynamic_element_index += 1
    return element_id
}

@(private)
_clay_attach_id :: proc(element_id: Clay_Element_Id) -> Clay_Element_Id {
    ctx := _clay_current_context
    open_layout_element := _clay_get_open_layout_element()
    id_alias := open_layout_element.id
    open_layout_element.id = element_id.id
    _clay_add_hash_map_item(element_id, open_layout_element, id_alias)
    _clay_array_set(&ctx.layout_element_id_strings, len(ctx.layout_elements) - 1, element_id.string_id)
    return element_id
}

// ── Update aspect ratio ───────────────────────────────────────────────────────

@(private)
_clay_update_aspect_ratio_box :: proc(layout_element: ^_Clay_Layout_Element) {
    if _clay_element_has_config(layout_element, .Aspect) {
        config := _clay_find_element_config_with_type(layout_element, .Aspect).aspect_ratio_element_config
        if config != nil && layout_element.dimensions.y == 0 {
            layout_element.dimensions.y = (1.0 / config.aspect_ratio) * layout_element.dimensions.x
        }
    }
}

// ── Text measurement caching ──────────────────────────────────────────────────

@(private)
_clay_hash_string_contents_with_config :: proc(text: string, config: ^Clay_Text_Element_Config) -> u32 {
    // Hash based on text content + font settings
    hash: u32 = 5381
    for i in 0..<len(text) {
        hash = ((hash << 5) + hash) + u32(text[i])
    }
    hash = ((hash << 5) + hash) + u32(config.font_id)
    hash = ((hash << 5) + hash) + u32(config.font_size)
    hash = ((hash << 5) + hash) + u32(config.letter_spacing)
    hash = ((hash << 5) + hash) + u32(config.line_height)
    return hash == 0 ? 1 : hash
}

@(private)
_clay_add_measured_word :: proc(word: _Clay_Measured_Word, previous_word: ^_Clay_Measured_Word) -> ^_Clay_Measured_Word {
    ctx := _clay_current_context
    new_index: i32
    if len(ctx.measured_words_free_list) > 0 {
        free_index := _clay_array_remove_swapback(&ctx.measured_words_free_list, len(ctx.measured_words_free_list) - 1, 0)
        _clay_array_set(&ctx.measured_words, free_index, word)
        new_index = free_index
    } else {
        _clay_array_add(&ctx.measured_words, word)
        new_index = i32(len(ctx.measured_words) - 1)
    }
    if previous_word != nil {
        previous_word.next = new_index
    }
    return _clay_array_get(&ctx.measured_words, new_index, &_measured_word_default)
}

@(private)
_clay_measure_text_cached :: proc(text: string, config: ^Clay_Text_Element_Config) -> ^_Clay_Measure_Text_Cache_Item {
    ctx := _clay_current_context
    if _clay_measure_text_fn == nil {
        if !ctx.text_measurement_function_not_set {
            ctx.text_measurement_function_not_set = true
            ctx.error_handler.error_handler_function(Clay_Error_Data{
                error_type = .Text_Measurement_Function_Not_Provided,
                error_text = "Clay_SetMeasureTextFunction() was not called before attempting to measure text.",
            })
        }
        return &_measure_text_cache_item_default
    }

    hash_key := _clay_hash_string_contents_with_config(text, config)
    hash_map_bucket := i32(hash_key % u32(cap(ctx.measure_text_hash_map)))
    item_index := _clay_array_get_value(&ctx.measure_text_hash_map, hash_map_bucket, 0)

    for item_index != 0 {
        item := _clay_array_get(&ctx.measure_text_hash_map_internal, item_index, &_measure_text_cache_item_default)
        if item.id == hash_key {
            item.generation = ctx.generation
            return item
        }
        item_index = item.next_index
    }

    // Cache miss - measure the text
    new_item_index: i32
    is_new: bool
    if len(ctx.measure_text_hash_map_internal_free_list) > 0 {
        new_item_index = _clay_array_remove_swapback(&ctx.measure_text_hash_map_internal_free_list,
            len(ctx.measure_text_hash_map_internal_free_list) - 1, 0)
        is_new = false
    } else {
        new_item_index = i32(len(ctx.measure_text_hash_map_internal))
        _clay_array_add(&ctx.measure_text_hash_map_internal, _Clay_Measure_Text_Cache_Item{})
        is_new = true
    }

    new_item := _clay_array_get(&ctx.measure_text_hash_map_internal, new_item_index, &_measure_text_cache_item_default)
    new_item.id = hash_key
    new_item.generation = ctx.generation
    new_item.measured_words_start_index = -1
    new_item.contains_newlines = false
    new_item.min_width = 0
    new_item.unwrapped_dimensions = {}

    // Walk through words and measure
    word_start : i32 = 0
    measured_words_start := i32(len(ctx.measured_words))
    new_item.measured_words_start_index = measured_words_start
    previous_word: ^_Clay_Measured_Word = nil

    for i in 0..= len(text) {
        is_end := i == len(text)
        ch: u8 = ' '
        if !is_end { ch = text[i] }

        is_space_or_newline := ch == ' ' || ch == '\n' || is_end
        if is_space_or_newline {
            word_len := i - word_start
            is_newline := ch == '\n'

            if word_len > 0 {
                // Measure the word
                word_slice := text[word_start:word_len]
                dims := _clay_measure_text_fn(word_slice, config, ctx.measure_text_user_data)
                word := _Clay_Measured_Word{
                    start_offset = word_start,
                    length       = word_len + (is_end ? 0 : 1), // include space
                    width        = dims.x + (is_end ? 0 : f32(config.letter_spacing)),
                    next         = -1,
                }
                if dims.x > new_item.min_width { new_item.min_width = dims.x }
                new_item.unwrapped_dimensions.x += word.width
                new_item.unwrapped_dimensions.y = dims.y
                previous_word = _clay_add_measured_word(word, previous_word)
                if new_item.measured_words_start_index == measured_words_start && !is_new {
                    new_item.measured_words_start_index = len(ctx.measured_words) - 1
                }
            }

            if is_newline {
                new_item.contains_newlines = true
                // Add a zero-length entry to signal newline
                nl_word := _Clay_Measured_Word{
                    start_offset = i,
                    length       = 0,
                    width        = 0,
                    next         = -1,
                }
                previous_word = _clay_add_measured_word(nl_word, previous_word)
            }

            word_start = i + 1
        }
    }

    // Link into hash map
    next_index := _clay_array_get_value(&ctx.measure_text_hash_map, hash_map_bucket, 0)
    new_item.next_index = next_index
    _clay_array_set(&ctx.measure_text_hash_map, hash_map_bucket, new_item_index)
    return new_item
}

// ── Point-in-rect ─────────────────────────────────────────────────────────────

@(private)
_clay_point_is_inside_rect :: proc(point: Clay_Vector2, rect: Clay_Bounding_Box) -> bool {
    return point.x >= rect.x && point.x <= rect.x + rect.width &&
           point.y >= rect.y && point.y <= rect.y + rect.height
}

// ── Open / close / configure elements ────────────────────────────────────────

@(private)
_clay_open_element :: proc() {
    ctx := _clay_current_context
    if ctx.layout_elements.length == ctx.layout_elements.capacity - 1 || ctx.boolean_warnings.max_elements_exceeded {
        ctx.boolean_warnings.max_elements_exceeded = true
        return
    }
    _clay_array_add(&ctx.layout_elements, _Clay_Layout_Element{}, &_layout_element_default)
    _clay_array_add(&ctx.open_layout_element_stack, ctx.layout_elements.length - 1, &_i32_default)

    if ctx.open_clip_element_stack.length > 0 {
        clip_id := _clay_array_get_value(&ctx.open_clip_element_stack, ctx.open_clip_element_stack.length - 1, 0)
        _clay_array_set(&ctx.layout_element_clip_element_ids, ctx.layout_elements.length - 1, clip_id)
    } else {
        _clay_array_set(&ctx.layout_element_clip_element_ids, ctx.layout_elements.length - 1, 0)
    }
}

@(private)
_clay_close_element :: proc() {
    ctx := _clay_current_context
    if ctx.boolean_warnings.max_elements_exceeded { return }

    open_layout_element := _clay_get_open_layout_element()
    layout_config := open_layout_element.layout_config
    element_has_scroll_h := false
    element_has_scroll_v := false

    for i in 0..<open_layout_element.element_configs.length {
        config := _clay_array_slice_get_impl(&open_layout_element.element_configs, i)
        if config.type == .Clip {
            element_has_scroll_h = config.config.clip_element_config.horizontal
            element_has_scroll_v = config.config.clip_element_config.vertical
            ctx.open_clip_element_stack.length -= 1
            break
        } else if config.type == .Floating {
            ctx.open_clip_element_stack.length -= 1
        }
    }

    left_right_padding := f32(layout_config.padding.left + layout_config.padding.right)
    top_bottom_padding := f32(layout_config.padding.top + layout_config.padding.bottom)

    // Attach children
    open_layout_element.children_or_text_content.children.elements =
        &ctx.layout_element_children.internal_array[ctx.layout_element_children.length]

    children_len := open_layout_element.children_or_text_content.children.length

    if layout_config.layout_direction == .Left_To_Right {
        open_layout_element.dimensions.width = left_right_padding
        open_layout_element.min_dimensions.width = left_right_padding
        for i in 0..<i32(children_len) {
            buf_idx := ctx.layout_element_children_buffer.length - i32(children_len) + i
            child_index := _clay_array_get_value(&ctx.layout_element_children_buffer, buf_idx, 0)
            child := _clay_array_get(&ctx.layout_elements, child_index, &_layout_element_default)
            open_layout_element.dimensions.width += child.dimensions.width
            if child.dimensions.height + top_bottom_padding > open_layout_element.dimensions.height {
                open_layout_element.dimensions.height = child.dimensions.height + top_bottom_padding
            }
            if !element_has_scroll_h { open_layout_element.min_dimensions.width += child.min_dimensions.width }
            if !element_has_scroll_v {
                if child.min_dimensions.height + top_bottom_padding > open_layout_element.min_dimensions.height {
                    open_layout_element.min_dimensions.height = child.min_dimensions.height + top_bottom_padding
                }
            }
            _clay_array_add(&ctx.layout_element_children, child_index, &_i32_default)
        }
        gap := f32(max(i32(children_len) - 1, 0) * i32(layout_config.child_gap))
        open_layout_element.dimensions.width += gap
        open_layout_element.min_dimensions.width += gap
    } else if layout_config.layout_direction == .Top_To_Bottom {
        open_layout_element.dimensions.height = top_bottom_padding
        open_layout_element.min_dimensions.height = top_bottom_padding
        for i in 0..<i32(children_len) {
            buf_idx := ctx.layout_element_children_buffer.length - i32(children_len) + i
            child_index := _clay_array_get_value(&ctx.layout_element_children_buffer, buf_idx, 0)
            child := _clay_array_get(&ctx.layout_elements, child_index, &_layout_element_default)
            open_layout_element.dimensions.height += child.dimensions.height
            if child.dimensions.width + left_right_padding > open_layout_element.dimensions.width {
                open_layout_element.dimensions.width = child.dimensions.width + left_right_padding
            }
            if !element_has_scroll_v { open_layout_element.min_dimensions.height += child.min_dimensions.height }
            if !element_has_scroll_h {
                if child.min_dimensions.width + left_right_padding > open_layout_element.min_dimensions.width {
                    open_layout_element.min_dimensions.width = child.min_dimensions.width + left_right_padding
                }
            }
            _clay_array_add(&ctx.layout_element_children, child_index, &_i32_default)
        }
        gap := f32(max(i32(children_len) - 1, 0) * i32(layout_config.child_gap))
        open_layout_element.dimensions.height += gap
        open_layout_element.min_dimensions.height += gap
    }

    ctx.layout_element_children_buffer.length -= i32(children_len)

    // Clamp width
    if layout_config.sizing.width.type != .Percent {
        if layout_config.sizing.width.size.min_max.max <= 0 {
            layout_config.sizing.width.size.min_max.max = _CLAY_MAXFLOAT
        }
        w := open_layout_element.dimensions.width
        w = max(w, layout_config.sizing.width.size.min_max.min)
        w = min(w, layout_config.sizing.width.size.min_max.max)
        open_layout_element.dimensions.width = w

        mw := open_layout_element.min_dimensions.width
        mw = max(mw, layout_config.sizing.width.size.min_max.min)
        mw = min(mw, layout_config.sizing.width.size.min_max.max)
        open_layout_element.min_dimensions.width = mw
    } else {
        open_layout_element.dimensions.width = 0
    }

    // Clamp height
    if layout_config.sizing.height.type != .Percent {
        if layout_config.sizing.height.size.min_max.max <= 0 {
            layout_config.sizing.height.size.min_max.max = _CLAY_MAXFLOAT
        }
        h := open_layout_element.dimensions.height
        h = max(h, layout_config.sizing.height.size.min_max.min)
        h = min(h, layout_config.sizing.height.size.min_max.max)
        open_layout_element.dimensions.height = h

        mh := open_layout_element.min_dimensions.height
        mh = max(mh, layout_config.sizing.height.size.min_max.min)
        mh = min(mh, layout_config.sizing.height.size.min_max.max)
        open_layout_element.min_dimensions.height = mh
    } else {
        open_layout_element.dimensions.height = 0
    }

    _clay_update_aspect_ratio_box(open_layout_element)

    element_is_floating := _clay_element_has_config(open_layout_element, .Floating)

    closing_element_index := _clay_array_remove_swapback(&ctx.open_layout_element_stack,
        ctx.open_layout_element_stack.length - 1, 0)
    open_layout_element = _clay_get_open_layout_element()

    if !element_is_floating && ctx.open_layout_element_stack.length > 1 {
        open_layout_element.children_or_text_content.children.length += 1
        _clay_array_add(&ctx.layout_element_children_buffer, closing_element_index, &_i32_default)
    }
}

@(private)
_clay_open_text_element :: proc(text: Clay_String, text_config: ^Clay_Text_Element_Config) {
    ctx := _clay_current_context
    if ctx.layout_elements.length == ctx.layout_elements.capacity - 1 || ctx.boolean_warnings.max_elements_exceeded {
        ctx.boolean_warnings.max_elements_exceeded = true
        return
    }

    parent_element := _clay_get_open_layout_element()
    _clay_array_add(&ctx.layout_elements, _Clay_Layout_Element{}, &_layout_element_default)
    text_element := _clay_array_get(&ctx.layout_elements, ctx.layout_elements.length - 1, &_layout_element_default)

    if ctx.open_clip_element_stack.length > 0 {
        clip_id := _clay_array_get_value(&ctx.open_clip_element_stack, ctx.open_clip_element_stack.length - 1, 0)
        _clay_array_set(&ctx.layout_element_clip_element_ids, ctx.layout_elements.length - 1, clip_id)
    } else {
        _clay_array_set(&ctx.layout_element_clip_element_ids, ctx.layout_elements.length - 1, 0)
    }

    _clay_array_add(&ctx.layout_element_children_buffer, ctx.layout_elements.length - 1, &_i32_default)

    text_measured := _clay_measure_text_cached(&text, text_config)
    element_id := _clay_hash_number(u32(parent_element.children_or_text_content.children.length), parent_element.id)
    text_element.id = element_id.id
    _clay_add_hash_map_item(element_id, text_element, 0)
    _clay_array_set(&ctx.layout_element_id_strings, ctx.layout_elements.length - 1, element_id.string_id)

    line_h := text_config.line_height > 0 ? f32(text_config.line_height) : text_measured.unwrapped_dimensions.height
    text_element.dimensions = Clay_Dimensions{text_measured.unwrapped_dimensions.width, line_h}
    text_element.min_dimensions = Clay_Dimensions{text_measured.min_width, line_h}

    data := _Clay_Text_Element_Data{
        text                 = text,
        preferred_dimensions = text_measured.unwrapped_dimensions,
        element_index        = ctx.layout_elements.length - 1,
    }
    text_element.children_or_text_content.text_element_data =
        _clay_array_add(&ctx.text_element_data, data, &_text_element_data_default)

    cfg := _Clay_Element_Config{
        type   = .Text,
        config = {text_element_config = text_config},
    }
    text_element.element_configs = _Clay_Element_Config_Array_Slice{
        length         = 1,
        internal_array = _clay_array_add(&ctx.element_configs, cfg, &_element_config_default),
    }
    text_element.layout_config = &CLAY_LAYOUT_DEFAULT
    parent_element.children_or_text_content.children.length += 1
}

@(private)
_clay_configure_open_element :: proc(declaration: Clay_Element_Declaration) {
    ctx := _clay_current_context
    open_layout_element := _clay_get_open_layout_element()
    open_layout_element.layout_config = _clay_store_layout_config(declaration.layout)

    // Validate percentages
    if (declaration.layout.sizing.width.type == .Percent && declaration.layout.sizing.width.size.percent > 1) ||
       (declaration.layout.sizing.height.type == .Percent && declaration.layout.sizing.height.size.percent > 1) {
        ctx.error_handler.error_handler_function(Clay_Error_Data{
            error_type = .Percentage_Over_1,
            error_text = _clay_string_lit("An element was configured with CLAY_SIZING_PERCENT, but the provided percentage value was over 1.0. Clay expects a value between 0 and 1, i.e. 20% is 0.2."),
        })
    }

    open_layout_element_id := declaration.id
    open_layout_element.element_configs.internal_array = &ctx.element_configs.internal_array[ctx.element_configs.length]

    // Attach shared config for background color / corner radius / user data
    shared_config: ^_Clay_Shared_Element_Config = nil
    if declaration.background_color.a > 0 {
        shared_config = _clay_store_shared_element_config(_Clay_Shared_Element_Config{
            background_color = declaration.background_color,
        })
        _clay_attach_element_config({shared_element_config = shared_config}, .Shared)
    }

    zero_corner_radius: Clay_Corner_Radius
    if !_clay_mem_compare(&declaration.corner_radius, &zero_corner_radius, size_of(Clay_Corner_Radius)) {
        if shared_config != nil {
            shared_config.corner_radius = declaration.corner_radius
        } else {
            shared_config = _clay_store_shared_element_config(_Clay_Shared_Element_Config{
                corner_radius = declaration.corner_radius,
            })
            _clay_attach_element_config({shared_element_config = shared_config}, .Shared)
        }
    }

    if declaration.user_data != nil {
        if shared_config != nil {
            shared_config.user_data = declaration.user_data
        } else {
            shared_config = _clay_store_shared_element_config(_Clay_Shared_Element_Config{
                user_data = declaration.user_data,
            })
            _clay_attach_element_config({shared_element_config = shared_config}, .Shared)
        }
    }

    if declaration.image.image_data != nil {
        _clay_attach_element_config(
            {image_element_config = _clay_store_image_element_config(declaration.image)}, .Image)
    }

    if declaration.aspect_ratio.aspect_ratio > 0 {
        _clay_attach_element_config(
            {aspect_ratio_element_config = _clay_store_aspect_ratio_element_config(declaration.aspect_ratio)}, .Aspect)
        _clay_array_add(&ctx.aspect_ratio_element_indexes, ctx.layout_elements.length - 1, &_i32_default)
    }

    if declaration.floating.attach_to != .None {
        floating_config := declaration.floating
        parent_stack_len := ctx.open_layout_element_stack.length
        hierarchical_parent := _clay_array_get(&ctx.layout_elements,
            _clay_array_get_value(&ctx.open_layout_element_stack, parent_stack_len - 2, 0), &_layout_element_default)

        if hierarchical_parent != nil {
            clip_element_id: u32 = 0
            if declaration.floating.attach_to == .Parent {
                floating_config.parent_id = hierarchical_parent.id
                if ctx.open_clip_element_stack.length > 0 {
                    clip_element_id = u32(_clay_array_get_value(&ctx.open_clip_element_stack,
                        ctx.open_clip_element_stack.length - 1, 0))
                }
            } else if declaration.floating.attach_to == .Element_With_Id {
                parent_item := _clay_get_hash_map_item(floating_config.parent_id)
                if parent_item == &_layout_element_hash_map_item_default {
                    ctx.error_handler.error_handler_function(Clay_Error_Data{
                        error_type = .Floating_Container_Parent_Not_Found,
                        error_text = _clay_string_lit("A floating element was declared with a parentId, but no element with that ID was found."),
                    })
                } else {
                    parent_offset := i32(uintptr(parent_item.layout_element) -
                        uintptr(ctx.layout_elements.internal_array)) / size_of(_Clay_Layout_Element)
                    clip_element_id = u32(_clay_array_get_value(&ctx.layout_element_clip_element_ids, parent_offset, 0))
                }
            } else if declaration.floating.attach_to == .Root {
                floating_config.parent_id = _clay_hash_string(_clay_string_lit("Clay__RootContainer"), 0, 0).id
            }

            if open_layout_element_id.id == 0 {
                open_layout_element_id = _clay_hash_string(_clay_string_lit("Clay__FloatingContainer"),
                    u32(ctx.layout_element_tree_roots.length), 0)
            }

            if declaration.floating.clip_to == .None { clip_element_id = 0 }

            current_element_index := _clay_array_get_value(&ctx.open_layout_element_stack,
                ctx.open_layout_element_stack.length - 1, 0)
            _clay_array_set(&ctx.layout_element_clip_element_ids, current_element_index, i32(clip_element_id))
            _clay_array_add(&ctx.open_clip_element_stack, i32(clip_element_id), &_i32_default)

            _clay_array_add(&ctx.layout_element_tree_roots, _Clay_Layout_Element_Tree_Root{
                layout_element_index = current_element_index,
                parent_id            = floating_config.parent_id,
                clip_element_id      = clip_element_id,
                z_index              = floating_config.z_index,
            }, &_layout_element_tree_root_default)

            _clay_attach_element_config(
                {floating_element_config = _clay_store_floating_element_config(floating_config)}, .Floating)
        }
    }

    if declaration.custom.custom_data != nil {
        _clay_attach_element_config(
            {custom_element_config = _clay_store_custom_element_config(declaration.custom)}, .Custom)
    }

    if open_layout_element_id.id != 0 {
        _clay_attach_id(open_layout_element_id)
    } else if open_layout_element.id == 0 {
        _clay_generate_id_for_anonymous_element(open_layout_element)
    }

    if declaration.clip.horizontal || declaration.clip.vertical {
        _clay_attach_element_config(
            {clip_element_config = _clay_store_clip_element_config(declaration.clip)}, .Clip)
        _clay_array_add(&ctx.open_clip_element_stack, i32(open_layout_element.id), &_i32_default)

        // Retrieve or create scroll state
        scroll_offset: ^_Clay_Scroll_Container_Data_Internal = nil
        for i in 0..<ctx.scroll_container_datas.length {
            mapping := _clay_array_get(&ctx.scroll_container_datas, i, &_scroll_container_data_internal_default)
            if open_layout_element.id == mapping.element_id {
                scroll_offset = mapping
                scroll_offset.layout_element = open_layout_element
                scroll_offset.open_this_frame = true
            }
        }
        if scroll_offset == nil {
            scroll_offset = _clay_array_add(&ctx.scroll_container_datas, _Clay_Scroll_Container_Data_Internal{
                layout_element = open_layout_element,
                scroll_origin  = {-1, -1},
                element_id     = open_layout_element.id,
                open_this_frame = true,
            }, &_scroll_container_data_internal_default)
        }
        if ctx.external_scroll_handling_enabled && _clay_query_scroll_offset_fn != nil {
            scroll_offset.scroll_position = _clay_query_scroll_offset_fn(
                scroll_offset.element_id, ctx.query_scroll_offset_user_data)
        }
    }

    zero_border_width: Clay_Border_Width
    if !_clay_mem_compare(&declaration.border.width, &zero_border_width, size_of(Clay_Border_Width)) {
        _clay_attach_element_config(
            {border_element_config = _clay_store_border_element_config(declaration.border)}, .Border)
    }
}

// ── Memory initialization ─────────────────────────────────────────────────────

@(private)
_clay_initialize_ephemeral_memory :: proc(ctx: ^_Clay_Context) {
    max_element_count := ctx.max_element_count
    arena := &ctx.internal_arena
    arena.next_allocation = ctx.arena_reset_offset

    ctx.layout_element_children_buffer = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.layout_elements                = _clay_array_allocate_arena(max_element_count, _Clay_Layout_Element, arena)
    ctx.warnings                       = _clay_array_allocate_arena(100, _Clay_Warning, arena)
    ctx.layout_configs                 = _clay_array_allocate_arena(max_element_count, Clay_Layout_Config, arena)
    ctx.element_configs                = _clay_array_allocate_arena(max_element_count, _Clay_Element_Config, arena)
    ctx.text_element_configs           = _clay_array_allocate_arena(max_element_count, Clay_Text_Element_Config, arena)
    ctx.aspect_ratio_element_configs   = _clay_array_allocate_arena(max_element_count, Clay_Aspect_Ratio_Element_Config, arena)
    ctx.image_element_configs          = _clay_array_allocate_arena(max_element_count, Clay_Image_Element_Config, arena)
    ctx.floating_element_configs       = _clay_array_allocate_arena(max_element_count, Clay_Floating_Element_Config, arena)
    ctx.clip_element_configs           = _clay_array_allocate_arena(max_element_count, Clay_Clip_Element_Config, arena)
    ctx.custom_element_configs         = _clay_array_allocate_arena(max_element_count, Clay_Custom_Element_Config, arena)
    ctx.border_element_configs         = _clay_array_allocate_arena(max_element_count, Clay_Border_Element_Config, arena)
    ctx.shared_element_configs         = _clay_array_allocate_arena(max_element_count, _Clay_Shared_Element_Config, arena)
    ctx.layout_element_id_strings      = _clay_array_allocate_arena(max_element_count, Clay_String, arena)
    ctx.wrapped_text_lines             = _clay_array_allocate_arena(max_element_count, _Clay_Wrapped_Text_Line, arena)
    ctx.layout_element_tree_node_array1 = _clay_array_allocate_arena(max_element_count, _Clay_Layout_Element_Tree_Node, arena)
    ctx.layout_element_tree_roots      = _clay_array_allocate_arena(max_element_count, _Clay_Layout_Element_Tree_Root, arena)
    ctx.layout_element_children        = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.open_layout_element_stack      = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.text_element_data              = _clay_array_allocate_arena(max_element_count, _Clay_Text_Element_Data, arena)
    ctx.aspect_ratio_element_indexes   = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.render_commands                = _clay_array_allocate_arena(max_element_count, Clay_Render_Command, arena)
    ctx.tree_node_visited              = _clay_array_allocate_arena(max_element_count, bool, arena)
    ctx.tree_node_visited.length       = ctx.tree_node_visited.capacity
    ctx.open_clip_element_stack        = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.reusable_element_index_buffer  = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.layout_element_clip_element_ids = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.dynamic_string_data            = _clay_array_allocate_arena(max_element_count, u8, arena)
}

@(private)
_clay_initialize_persistent_memory :: proc(ctx: ^_Clay_Context) {
    max_element_count := ctx.max_element_count
    max_word_cache    := ctx.max_measure_text_cache_word_count
    arena := &ctx.internal_arena

    ctx.scroll_container_datas              = _clay_array_allocate_arena(10, _Clay_Scroll_Container_Data_Internal, arena)
    ctx.layout_elements_hash_map_internal   = _clay_array_allocate_arena(max_element_count, _Clay_Layout_Element_Hash_Map_Item, arena)
    ctx.layout_elements_hash_map            = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.measure_text_hash_map_internal      = _clay_array_allocate_arena(max_element_count, _Clay_Measure_Text_Cache_Item, arena)
    ctx.measure_text_hash_map_internal_free_list = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.measured_words_free_list            = _clay_array_allocate_arena(max_word_cache, i32, arena)
    ctx.measure_text_hash_map               = _clay_array_allocate_arena(max_element_count, i32, arena)
    ctx.measured_words                      = _clay_array_allocate_arena(max_word_cache, _Clay_Measured_Word, arena)
    ctx.pointer_over_ids                    = _clay_array_allocate_arena(max_element_count, Clay_Element_Id, arena)
    ctx.debug_element_data                  = _clay_array_allocate_arena(max_element_count, _Clay_Debug_Element_Data, arena)

    ctx.arena_reset_offset = arena.next_allocation
}

@(private)
_clay_context_allocate_arena :: proc(arena: ^_Clay_Internal_Arena) -> ^_Clay_Context {
    total_size := size_of(_Clay_Context)
    next_alloc_offset := arena.next_allocation + (64 - (arena.next_allocation % 64))
    if next_alloc_offset + uint(total_size) > arena.capacity { return nil }
    ctx := (^_Clay_Context)(uintptr(arena.memory) + uintptr(next_alloc_offset))
    arena.next_allocation = next_alloc_offset + uint(total_size)
    ctx^ = {} // zero-initialize
    return ctx
}

// ── Add render command ────────────────────────────────────────────────────────

@(private)
_clay_add_render_command :: proc(render_command: Clay_Render_Command) {
    ctx := _clay_current_context
    if ctx.render_commands.length < ctx.render_commands.capacity - 1 {
        _clay_array_add(&ctx.render_commands, render_command, &_render_command_default)
    } else if !ctx.boolean_warnings.max_render_commands_exceeded {
        ctx.boolean_warnings.max_render_commands_exceeded = true
        ctx.error_handler.error_handler_function(Clay_Error_Data{
            error_type = .Elements_Capacity_Exceeded,
            error_text = _clay_string_lit("Clay ran out of capacity while attempting to create render commands."),
        })
    }
}

@(private)
_clay_element_is_offscreen :: proc(bounding_box: ^Clay_Bounding_Box) -> bool {
    ctx := _clay_current_context
    if ctx.disable_culling { return false }
    return bounding_box.x > ctx.layout_dimensions.width  ||
           bounding_box.y > ctx.layout_dimensions.height ||
           bounding_box.x + bounding_box.width  < 0      ||
           bounding_box.y + bounding_box.height < 0
}

// ── Size containers along axis ────────────────────────────────────────────────

@(private)
_clay_size_containers_along_axis :: proc(x_axis: bool) {
    ctx := _clay_current_context
    bfs_buffer := &ctx.layout_element_children_buffer
    resizable_buffer := &ctx.open_layout_element_stack

    for root_index in 0..<ctx.layout_element_tree_roots.length {
        bfs_buffer.length = 0
        root := _clay_array_get(&ctx.layout_element_tree_roots, root_index, &_layout_element_tree_root_default)
        root_element := _clay_array_get(&ctx.layout_elements, root.layout_element_index, &_layout_element_default)
        _clay_array_add(bfs_buffer, root.layout_element_index, &_i32_default)

        // Size floating containers to their parents
        if _clay_element_has_config(root_element, .Floating) {
            floating_cfg := _clay_find_element_config_with_type(root_element, .Floating).floating_element_config
            parent_item := _clay_get_hash_map_item(floating_cfg.parent_id)
            if parent_item != nil && parent_item != &_layout_element_hash_map_item_default {
                parent := parent_item.layout_element
                if root_element.layout_config.sizing.width.type == .Grow {
                    root_element.dimensions.width = parent.dimensions.width
                }
                if root_element.layout_config.sizing.height.type == .Grow {
                    root_element.dimensions.height = parent.dimensions.height
                }
            }
        }

        root_element.dimensions.width  = clamp(root_element.dimensions.width,  root_element.layout_config.sizing.width.size.min_max.min,  root_element.layout_config.sizing.width.size.min_max.max)
        root_element.dimensions.height = clamp(root_element.dimensions.height, root_element.layout_config.sizing.height.size.min_max.min, root_element.layout_config.sizing.height.size.min_max.max)

        for i in 0..<bfs_buffer.length {
            parent_index := _clay_array_get_value(bfs_buffer, i, 0)
            parent := _clay_array_get(&ctx.layout_elements, parent_index, &_layout_element_default)
            parent_style_config := parent.layout_config
            grow_container_count := 0
            parent_size := x_axis ? parent.dimensions.width : parent.dimensions.height
            parent_padding := f32(x_axis ? (parent.layout_config.padding.left + parent.layout_config.padding.right) : (parent.layout_config.padding.top  + parent.layout_config.padding.bottom))
            inner_content_size: f32 = 0
            total_padding_and_child_gaps := parent_padding
            sizing_along_axis := (x_axis && parent_style_config.layout_direction == .Left_To_Right) ||
                                 (!x_axis && parent_style_config.layout_direction == .Top_To_Bottom)
            resizable_buffer.length = 0
            parent_child_gap := f32(parent_style_config.child_gap)

            children_len := parent.children_or_text_content.children.length
            for child_offset in 0..<i32(children_len) {
                child_element_index := parent.children_or_text_content.children.elements[child_offset]
                child_element := _clay_array_get(&ctx.layout_elements, child_element_index, &_layout_element_default)
                child_sizing := x_axis ? child_element.layout_config.sizing.width : child_element.layout_config.sizing.height
                child_size := x_axis ? child_element.dimensions.width : child_element.dimensions.height

                if !_clay_element_has_config(child_element, .Text) && child_element.children_or_text_content.children.length > 0 {
                    _clay_array_add(bfs_buffer, child_element_index, &_i32_default)
                }

                if child_sizing.type != .Percent && child_sizing.type != .Fixed &&
                   (!_clay_element_has_config(child_element, .Text) ||
                    _clay_find_element_config_with_type(child_element, .Text).text_element_config.wrap_mode == .Words) {
                    _clay_array_add(resizable_buffer, child_element_index, &_i32_default)
                }

                if sizing_along_axis {
                    inner_content_size += (child_sizing.type == .Percent ? 0 : child_size)
                    if child_sizing.type == .Grow { grow_container_count += 1 }
                    if child_offset > 0 {
                        inner_content_size += parent_child_gap
                        total_padding_and_child_gaps += parent_child_gap
                    }
                } else {
                    if child_size > inner_content_size { inner_content_size = child_size }
                }
            }

            // Expand percentage containers
            for child_offset in 0..<i32(children_len) {
                child_element_index := parent.children_or_text_content.children.elements[child_offset]
                child_element := _clay_array_get(&ctx.layout_elements, child_element_index, &_layout_element_default)
                child_sizing := x_axis ? child_element.layout_config.sizing.width : child_element.layout_config.sizing.height
                if child_sizing.type == .Percent {
                    new_size := (parent_size - total_padding_and_child_gaps) * child_sizing.size.percent
                    if x_axis { child_element.dimensions.width  = new_size } else { child_element.dimensions.height = new_size }
                    if sizing_along_axis { inner_content_size += new_size }
                    _clay_update_aspect_ratio_box(child_element)
                }
            }

            if sizing_along_axis {
                size_to_distribute := parent_size - parent_padding - inner_content_size
                if size_to_distribute < 0 {
                    // Compress
                    clip_cfg := _clay_find_element_config_with_type(parent, .Clip).clip_element_config
                    if clip_cfg != nil {
                        if (x_axis && clip_cfg.horizontal) || (!x_axis && clip_cfg.vertical) { continue }
                    }
                    for size_to_distribute < -_CLAY_EPSILON && resizable_buffer.length > 0 {
                        largest: f32 = 0
                        second_largest: f32 = 0
                        width_to_add := size_to_distribute
                        for ci in 0..<resizable_buffer.length {
                            child := _clay_array_get(&ctx.layout_elements,
                                _clay_array_get_value(resizable_buffer, ci, 0), &_layout_element_default)
                            cs := x_axis ? child.dimensions.width : child.dimensions.height
                            if _clay_float_equal(cs, largest) { continue }
                            if cs > largest {
                                second_largest = largest; largest = cs
                            } else if cs < largest {
                                if cs > second_largest { second_largest = cs }
                                width_to_add = second_largest - largest
                            }
                        }
                        if size_to_distribute / f32(resizable_buffer.length) > width_to_add {
                            width_to_add = size_to_distribute / f32(resizable_buffer.length)
                        }
                        for ci := i32(0); ci < resizable_buffer.length; ci += 1 {
                            child := _clay_array_get(&ctx.layout_elements,
                                _clay_array_get_value(resizable_buffer, ci, 0), &_layout_element_default)
                            cs_ptr := x_axis ? &child.dimensions.width : &child.dimensions.height
                            min_s := x_axis ? child.min_dimensions.width : child.min_dimensions.height
                            if _clay_float_equal(cs_ptr^, largest) {
                                prev := cs_ptr^
                                cs_ptr^ += width_to_add
                                if cs_ptr^ <= min_s {
                                    cs_ptr^ = min_s
                                    _clay_array_remove_swapback(resizable_buffer, ci, 0)
                                    ci -= 1
                                }
                                size_to_distribute -= cs_ptr^ - prev
                            }
                        }
                    }
                } else if size_to_distribute > 0 && grow_container_count > 0 {
                    // Grow
                    for ci := i32(0); ci < resizable_buffer.length; ci += 1 {
                        child := _clay_array_get(&ctx.layout_elements,
                            _clay_array_get_value(resizable_buffer, ci, 0), &_layout_element_default)
                        cs_type := x_axis ? child.layout_config.sizing.width.type : child.layout_config.sizing.height.type
                        if cs_type != .Grow {
                            _clay_array_remove_swapback(resizable_buffer, ci, 0)
                            ci -= 1
                        }
                    }
                    for size_to_distribute > _CLAY_EPSILON && resizable_buffer.length > 0 {
                        smallest := _CLAY_MAXFLOAT
                        second_smallest := _CLAY_MAXFLOAT
                        width_to_add := size_to_distribute
                        for ci in 0..<resizable_buffer.length {
                            child := _clay_array_get(&ctx.layout_elements,
                                _clay_array_get_value(resizable_buffer, ci, 0), &_layout_element_default)
                            cs := x_axis ? child.dimensions.width : child.dimensions.height
                            if _clay_float_equal(cs, smallest) { continue }
                            if cs < smallest {
                                second_smallest = smallest; smallest = cs
                            } else if cs > smallest {
                                if cs < second_smallest { second_smallest = cs }
                                width_to_add = second_smallest - smallest
                            }
                        }
                        if size_to_distribute / f32(resizable_buffer.length) < width_to_add {
                            width_to_add = size_to_distribute / f32(resizable_buffer.length)
                        }
                        for ci := i32(0); ci < resizable_buffer.length; ci += 1 {
                            child := _clay_array_get(&ctx.layout_elements,
                                _clay_array_get_value(resizable_buffer, ci, 0), &_layout_element_default)
                            cs_ptr := x_axis ? &child.dimensions.width : &child.dimensions.height
                            max_s := x_axis ? child.layout_config.sizing.width.size.min_max.max : child.layout_config.sizing.height.size.min_max.max
                            if _clay_float_equal(cs_ptr^, smallest) {
                                prev := cs_ptr^
                                cs_ptr^ += width_to_add
                                if cs_ptr^ >= max_s {
                                    cs_ptr^ = max_s
                                    _clay_array_remove_swapback(resizable_buffer, ci, 0)
                                    ci -= 1
                                }
                                size_to_distribute -= cs_ptr^ - prev
                            }
                        }
                    }
                }
            } else {
                // Off-axis sizing
                for ci in 0..<resizable_buffer.length {
                    child_element := _clay_array_get(&ctx.layout_elements,
                        _clay_array_get_value(resizable_buffer, ci, 0), &_layout_element_default)
                    child_sizing := x_axis ? child_element.layout_config.sizing.width : child_element.layout_config.sizing.height
                    min_s := x_axis ? child_element.min_dimensions.width : child_element.min_dimensions.height
                    cs_ptr := x_axis ? &child_element.dimensions.width : &child_element.dimensions.height
                    max_s := parent_size - parent_padding
                    if _clay_element_has_config(parent, .Clip) {
                        clip_cfg := _clay_find_element_config_with_type(parent, .Clip).clip_element_config
                        if (x_axis && clip_cfg.horizontal) || (!x_axis && clip_cfg.vertical) {
                            if inner_content_size > max_s { max_s = inner_content_size }
                        }
                    }
                    if child_sizing.type == .Grow {
                        new_s := min(max_s, child_sizing.size.min_max.max)
                        cs_ptr^ = new_s
                    }
                    cs_ptr^ = max(min_s, min(cs_ptr^, max_s))
                }
            }
        }
    }
}

@(private)
_clay_int_to_string :: proc(integer: i32) -> Clay_String {
    if integer == 0 { return _clay_string_lit("0") }
    ctx := _clay_current_context
    chars := ([^]u8)(&ctx.dynamic_string_data.internal_array[ctx.dynamic_string_data.length])
    length: i32 = 0
    sign := integer
    n := integer
    if n < 0 { n = -n }
    for n > 0 {
        chars[length] = u8(n % 10 + '0')
        length += 1
        n /= 10
    }
    if sign < 0 {
        chars[length] = '-'
        length += 1
    }
    // Reverse
    j: i32 = 0; k := length - 1
    for j < k {
        chars[j], chars[k] = chars[k], chars[j]
        j += 1; k -= 1
    }
    ctx.dynamic_string_data.length += length
    return Clay_String{length = length, chars = chars}
}

// ── Calculate final layout ────────────────────────────────────────────────────

@(private)
_clay_calculate_final_layout :: proc() {
    ctx := _clay_current_context

    _clay_size_containers_along_axis(true) // X axis

    // Wrap text
    for text_element_index in 0..<ctx.text_element_data.length {
        text_element_data := _clay_array_get(&ctx.text_element_data, text_element_index, &_text_element_data_default)
        text_element_data.wrapped_lines = _Clay_Wrapped_Text_Line_Array_Slice{
            length         = 0,
            internal_array = &ctx.wrapped_text_lines.internal_array[ctx.wrapped_text_lines.length],
        }
        container_element := _clay_array_get(&ctx.layout_elements, text_element_data.element_index, &_layout_element_default)
        text_config := _clay_find_element_config_with_type(container_element, .Text).text_element_config
        measure_cache_item := _clay_measure_text_cached(&text_element_data.text, text_config)
        line_width: f32 = 0
        line_height := text_config.line_height > 0 ? f32(text_config.line_height) : text_element_data.preferred_dimensions.height
        line_length_chars: i32 = 0
        line_start_offset: i32 = 0

        if !measure_cache_item.contains_newlines && text_element_data.preferred_dimensions.width <= container_element.dimensions.width {
            _clay_array_add(&ctx.wrapped_text_lines, _Clay_Wrapped_Text_Line{
                dimensions = container_element.dimensions,
                line       = text_element_data.text,
            }, &_wrapped_text_line_default)
            text_element_data.wrapped_lines.length += 1
            continue
        }

        space_str := Clay_String_Slice{length = 1, chars = raw_data(" "), base_chars = raw_data(" ")}
        space_width := _clay_measure_text_fn != nil ? _clay_measure_text_fn(space_str, text_config, ctx.measure_text_user_data).width : 0

        word_index := measure_cache_item.measured_words_start_index
        for word_index != -1 {
            if ctx.wrapped_text_lines.length > ctx.wrapped_text_lines.capacity - 1 { break }
            measured_word := _clay_array_get(&ctx.measured_words, word_index, &_measured_word_default)

            if line_length_chars == 0 && line_width + measured_word.width > container_element.dimensions.width {
                // Only word on line is too large - render it anyway
                _clay_array_add(&ctx.wrapped_text_lines, _Clay_Wrapped_Text_Line{
                    dimensions = {measured_word.width, line_height},
                    line       = Clay_String{length = measured_word.length, chars = &text_element_data.text.chars[measured_word.start_offset]},
                }, &_wrapped_text_line_default)
                text_element_data.wrapped_lines.length += 1
                word_index = measured_word.next
                line_start_offset = measured_word.start_offset + measured_word.length
            } else if measured_word.length == 0 || line_width + measured_word.width > container_element.dimensions.width {
                // Start new line
                final_char_is_space := line_length_chars > 0 && text_element_data.text.chars[line_start_offset + line_length_chars - 1] == ' '
                adj_width := line_width + (final_char_is_space ? -space_width : 0)
                adj_len   := line_length_chars + (final_char_is_space ? -1 : 0)
                _clay_array_add(&ctx.wrapped_text_lines, _Clay_Wrapped_Text_Line{
                    dimensions = {adj_width, line_height},
                    line       = Clay_String{length = adj_len, chars = &text_element_data.text.chars[line_start_offset]},
                }, &_wrapped_text_line_default)
                text_element_data.wrapped_lines.length += 1
                if line_length_chars == 0 || measured_word.length == 0 {
                    word_index = measured_word.next
                }
                line_width = 0
                line_length_chars = 0
                line_start_offset = measured_word.start_offset
            } else {
                line_width += measured_word.width + f32(text_config.letter_spacing)
                line_length_chars += measured_word.length
                word_index = measured_word.next
            }
        }
        if line_length_chars > 0 {
            _clay_array_add(&ctx.wrapped_text_lines, _Clay_Wrapped_Text_Line{
                dimensions = {line_width - f32(text_config.letter_spacing), line_height},
                line       = Clay_String{length = line_length_chars, chars = &text_element_data.text.chars[line_start_offset]},
            }, &_wrapped_text_line_default)
            text_element_data.wrapped_lines.length += 1
        }
        container_element.dimensions.height = line_height * f32(text_element_data.wrapped_lines.length)
    }

    // Scale vertical heights by aspect ratio
    for i in 0..<ctx.aspect_ratio_element_indexes.length {
        aspect_element := _clay_array_get(&ctx.layout_elements,
            _clay_array_get_value(&ctx.aspect_ratio_element_indexes, i, 0), &_layout_element_default)
        config := _clay_find_element_config_with_type(aspect_element, .Aspect).aspect_ratio_element_config
        if config != nil {
            aspect_element.dimensions.height = (1.0 / config.aspect_ratio) * aspect_element.dimensions.width
            aspect_element.layout_config.sizing.height.size.min_max.max = aspect_element.dimensions.height
        }
    }

    // Propagate height changes upwards via DFS
    dfs_buffer := &ctx.layout_element_tree_node_array1
    dfs_buffer.length = 0
    for i in 0..<ctx.layout_element_tree_roots.length {
        root := _clay_array_get(&ctx.layout_element_tree_roots, i, &_layout_element_tree_root_default)
        ctx.tree_node_visited.internal_array[dfs_buffer.length] = false
        _clay_array_add(dfs_buffer, _Clay_Layout_Element_Tree_Node{
            layout_element = _clay_array_get(&ctx.layout_elements, root.layout_element_index, &_layout_element_default),
        }, &_layout_element_tree_node_default)
    }

    for dfs_buffer.length > 0 {
        current_tree_node := _clay_array_get(dfs_buffer, dfs_buffer.length - 1, &_layout_element_tree_node_default)
        current_element := current_tree_node.layout_element
        if !ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] {
            ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] = true
            if _clay_element_has_config(current_element, .Text) || current_element.children_or_text_content.children.length == 0 {
                dfs_buffer.length -= 1
                continue
            }
            for i in 0..<i32(current_element.children_or_text_content.children.length) {
                ctx.tree_node_visited.internal_array[dfs_buffer.length] = false
                _clay_array_add(dfs_buffer, _Clay_Layout_Element_Tree_Node{
                    layout_element = _clay_array_get(&ctx.layout_elements,
                        current_element.children_or_text_content.children.elements[i], &_layout_element_default),
                }, &_layout_element_tree_node_default)
            }
            continue
        }
        dfs_buffer.length -= 1

        layout_config := current_element.layout_config
        if layout_config.layout_direction == .Left_To_Right {
            for j in 0..<i32(current_element.children_or_text_content.children.length) {
                child_element := _clay_array_get(&ctx.layout_elements,
                    current_element.children_or_text_content.children.elements[j], &_layout_element_default)
                child_h_with_padding := max(child_element.dimensions.height + f32(layout_config.padding.top + layout_config.padding.bottom),
                    current_element.dimensions.height)
                new_h := clamp(child_h_with_padding, layout_config.sizing.height.size.min_max.min, layout_config.sizing.height.size.min_max.max)
                current_element.dimensions.height = new_h
            }
        } else if layout_config.layout_direction == .Top_To_Bottom {
            content_h := f32(layout_config.padding.top + layout_config.padding.bottom)
            for j in 0..<i32(current_element.children_or_text_content.children.length) {
                child_element := _clay_array_get(&ctx.layout_elements,
                    current_element.children_or_text_content.children.elements[j], &_layout_element_default)
                content_h += child_element.dimensions.height
            }
            content_h += f32(max(i32(current_element.children_or_text_content.children.length) - 1, 0) * i32(layout_config.child_gap))
            current_element.dimensions.height = clamp(content_h, layout_config.sizing.height.size.min_max.min, layout_config.sizing.height.size.min_max.max)
        }
    }

    _clay_size_containers_along_axis(false) // Y axis

    // Scale horizontal widths by aspect ratio
    for i in 0..<ctx.aspect_ratio_element_indexes.length {
        aspect_element := _clay_array_get(&ctx.layout_elements,
            _clay_array_get_value(&ctx.aspect_ratio_element_indexes, i, 0), &_layout_element_default)
        config := _clay_find_element_config_with_type(aspect_element, .Aspect).aspect_ratio_element_config
        if config != nil {
            aspect_element.dimensions.width = config.aspect_ratio * aspect_element.dimensions.height
        }
    }

    // Sort tree roots by z-index (bubble sort)
    sort_max := ctx.layout_element_tree_roots.length - 1
    for sort_max > 0 {
        for i in 0..<sort_max {
            current := _clay_array_get(&ctx.layout_element_tree_roots, i, &_layout_element_tree_root_default)
            next    := _clay_array_get(&ctx.layout_element_tree_roots, i + 1, &_layout_element_tree_root_default)
            if next.z_index < current.z_index {
                tmp := current^; current^ = next^; next^ = tmp
            }
        }
        sort_max -= 1
    }

    // Generate render commands via DFS
    ctx.render_commands.length = 0
    dfs_buffer.length = 0

    for root_index in 0..<ctx.layout_element_tree_roots.length {
        dfs_buffer.length = 0
        root := _clay_array_get(&ctx.layout_element_tree_roots, root_index, &_layout_element_tree_root_default)
        root_element := _clay_array_get(&ctx.layout_elements, root.layout_element_index, &_layout_element_default)
        root_position: Clay_Vector2

        // Position floating elements
        if _clay_element_has_config(root_element, .Floating) {
            parent_hash_map_item := _clay_get_hash_map_item(root.parent_id)
            if parent_hash_map_item != nil && parent_hash_map_item != &_layout_element_hash_map_item_default {
                config := _clay_find_element_config_with_type(root_element, .Floating).floating_element_config
                root_dims := root_element.dimensions
                parent_bb := parent_hash_map_item.bounding_box
                target: Clay_Vector2

                // X attach
                switch config.attach_points.parent {
                    case .Left_Top, .Left_Center, .Left_Bottom:     target.x = parent_bb.x
                    case .Center_Top, .Center_Center, .Center_Bottom: target.x = parent_bb.x + parent_bb.width / 2
                    case .Right_Top, .Right_Center, .Right_Bottom:  target.x = parent_bb.x + parent_bb.width
                }
                switch config.attach_points.element {
                    case .Left_Top, .Left_Center, .Left_Bottom:     // no adjustment
                    case .Center_Top, .Center_Center, .Center_Bottom: target.x -= root_dims.width / 2
                    case .Right_Top, .Right_Center, .Right_Bottom:  target.x -= root_dims.width
                }
                // Y attach
                switch config.attach_points.parent {
                    case .Left_Top, .Right_Top, .Center_Top:         target.y = parent_bb.y
                    case .Left_Center, .Center_Center, .Right_Center: target.y = parent_bb.y + parent_bb.height / 2
                    case .Left_Bottom, .Center_Bottom, .Right_Bottom: target.y = parent_bb.y + parent_bb.height
                }
                switch config.attach_points.element {
                    case .Left_Top, .Right_Top, .Center_Top:         // no adjustment
                    case .Left_Center, .Center_Center, .Right_Center: target.y -= root_dims.height / 2
                    case .Left_Bottom, .Center_Bottom, .Right_Bottom: target.y -= root_dims.height
                }
                target.x += config.offset.x
                target.y += config.offset.y
                root_position = target
            }
        }

        if root.clip_element_id != 0 {
            clip_hash_map_item := _clay_get_hash_map_item(root.clip_element_id)
            if clip_hash_map_item != nil {
                if ctx.external_scroll_handling_enabled {
                    clip_config := _clay_find_element_config_with_type(clip_hash_map_item.layout_element, .Clip).clip_element_config
                    if clip_config != nil {
                        if clip_config.horizontal { root_position.x += clip_config.child_offset.x }
                        if clip_config.vertical   { root_position.y += clip_config.child_offset.y }
                    }
                    // Skip scissor for externally handled scroll
                } else {
                    _clay_add_render_command(Clay_Render_Command{
                        bounding_box = clip_hash_map_item.bounding_box,
                        id           = _clay_hash_number(root_element.id, u32(root_element.children_or_text_content.children.length) + 10).id,
                        z_index      = root.z_index,
                        command_type = .Scissor_Start,
                    })
                }
            }
        }

        _clay_array_add(dfs_buffer, _Clay_Layout_Element_Tree_Node{
            layout_element    = root_element,
            position          = root_position,
            next_child_offset = {f32(root_element.layout_config.padding.left), f32(root_element.layout_config.padding.top)},
        }, &_layout_element_tree_node_default)

        ctx.tree_node_visited.internal_array[0] = false

        for dfs_buffer.length > 0 {
            current_tree_node := _clay_array_get(dfs_buffer, dfs_buffer.length - 1, &_layout_element_tree_node_default)
            current_element := current_tree_node.layout_element
            layout_config := current_element.layout_config
            scroll_offset: Clay_Vector2

            if !ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] {
                ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] = true

                current_bb := Clay_Bounding_Box{
                    current_tree_node.position.x,
                    current_tree_node.position.y,
                    current_element.dimensions.width,
                    current_element.dimensions.height,
                }

                // Expand for floating
                if _clay_element_has_config(current_element, .Floating) {
                    fc := _clay_find_element_config_with_type(current_element, .Floating).floating_element_config
                    current_bb.x      -= fc.expand.width
                    current_bb.width  += fc.expand.width * 2
                    current_bb.y      -= fc.expand.height
                    current_bb.height += fc.expand.height * 2
                }

                scroll_container_data: ^_Clay_Scroll_Container_Data_Internal = nil
                if _clay_element_has_config(current_element, .Clip) {
                    clip_config := _clay_find_element_config_with_type(current_element, .Clip).clip_element_config
                    for i in 0..<ctx.scroll_container_datas.length {
                        mapping := _clay_array_get(&ctx.scroll_container_datas, i, &_scroll_container_data_internal_default)
                        if mapping.layout_element == current_element {
                            scroll_container_data = mapping
                            mapping.bounding_box  = current_bb
                            scroll_offset = clip_config.child_offset
                            if ctx.external_scroll_handling_enabled { scroll_offset = {} }
                            break
                        }
                    }
                }

                hash_map_item := _clay_get_hash_map_item(current_element.id)
                if hash_map_item != nil {
                    hash_map_item.bounding_box = current_bb
                    if hash_map_item.id_alias != 0 {
                        alias_item := _clay_get_hash_map_item(hash_map_item.id_alias)
                        if alias_item != nil { alias_item.bounding_box = current_bb }
                    }
                }

                // Sort config indexes for render ordering
                sorted_config_indexes: [20]i32
                for i in 0..<current_element.element_configs.length {
                    sorted_config_indexes[i] = i
                }
                sm := current_element.element_configs.length - 1
                for sm > 0 {
                    for i in 0..<sm {
                        cur_i := sorted_config_indexes[i]
                        nxt_i := sorted_config_indexes[i + 1]
                        cur_t := _clay_array_slice_get_impl(&current_element.element_configs, cur_i).type
                        nxt_t := _clay_array_slice_get_impl(&current_element.element_configs, nxt_i).type
                        if nxt_t == .Clip || cur_t == .Border {
                            sorted_config_indexes[i] = nxt_i
                            sorted_config_indexes[i + 1] = cur_i
                        }
                    }
                    sm -= 1
                }

                emit_rectangle := false
                shared_config_ptr := _clay_find_element_config_with_type(current_element, .Shared).shared_element_config
                if shared_config_ptr != nil && shared_config_ptr.background_color.a > 0 {
                    emit_rectangle = true
                } else if shared_config_ptr == nil {
                    shared_config_ptr = &_shared_element_config_default
                }

                for eci in 0..<current_element.element_configs.length {
                    element_config := _clay_array_slice_get_impl(&current_element.element_configs, sorted_config_indexes[eci])
                    render_cmd := Clay_Render_Command{
                        bounding_box = current_bb,
                        user_data    = shared_config_ptr.user_data,
                        id           = current_element.id,
                        z_index      = root.z_index,
                    }
                    offscreen := _clay_element_is_offscreen(&current_bb)
                    should_render := !offscreen

                    switch element_config.type {
                        case .Aspect, .Floating, .Shared, .None:
                            should_render = false
                        case .Border:
                            should_render = false
                        case .Clip:
                            render_cmd.command_type = .Scissor_Start
                            render_cmd.render_data.clip = Clay_Clip_Render_Data{
                                horizontal = element_config.config.clip_element_config.horizontal,
                                vertical   = element_config.config.clip_element_config.vertical,
                            }
                        case .Image:
                            render_cmd.command_type = .Image
                            render_cmd.render_data.image = Clay_Image_Render_Data{
                                background_color = shared_config_ptr.background_color,
                                corner_radius    = shared_config_ptr.corner_radius,
                                image_data       = element_config.config.image_element_config.image_data,
                            }
                            emit_rectangle = false
                        case .Text:
                            if !should_render { break }
                            should_render = false
                            text_cfg := element_config.config.text_element_config
                            natural_line_h := current_element.children_or_text_content.text_element_data.preferred_dimensions.height
                            final_line_h := text_cfg.line_height > 0 ? f32(text_cfg.line_height) : natural_line_h
                            line_h_offset := (final_line_h - natural_line_h) / 2
                            y_position := line_h_offset
                            wrapped_lines := current_element.children_or_text_content.text_element_data.wrapped_lines
                            for line_index in 0..<wrapped_lines.length {
                                wrapped_line := _clay_array_slice_get_impl_wt(&wrapped_lines, line_index)
                                if wrapped_line.line.length == 0 {
                                    y_position += final_line_h
                                    continue
                                }
                                offset := current_bb.width - wrapped_line.dimensions.width
                                if text_cfg.text_alignment == .Left   { offset = 0 }
                                if text_cfg.text_alignment == .Center { offset /= 2 }
                                _clay_add_render_command(Clay_Render_Command{
                                    bounding_box = {current_bb.x + offset, current_bb.y + y_position, wrapped_line.dimensions.width, wrapped_line.dimensions.height},
                                    render_data  = {text = Clay_Text_Render_Data{
                                        string_contents = Clay_String_Slice{
                                            length     = wrapped_line.line.length,
                                            chars      = wrapped_line.line.chars,
                                            base_chars = current_element.children_or_text_content.text_element_data.text.chars,
                                        },
                                        text_color      = text_cfg.text_color,
                                        font_id         = text_cfg.font_id,
                                        font_size       = text_cfg.font_size,
                                        letter_spacing  = text_cfg.letter_spacing,
                                        line_height     = text_cfg.line_height,
                                    }},
                                    user_data    = text_cfg.user_data,
                                    id           = _clay_hash_number(u32(line_index), current_element.id).id,
                                    z_index      = root.z_index,
                                    command_type = .Text,
                                })
                                y_position += final_line_h
                                if !ctx.disable_culling && (current_bb.y + y_position > ctx.layout_dimensions.height) { break }
                            }
                        case .Custom:
                            render_cmd.command_type = .Custom
                            render_cmd.render_data.custom = Clay_Custom_Render_Data{
                                background_color = shared_config_ptr.background_color,
                                corner_radius    = shared_config_ptr.corner_radius,
                                custom_data      = element_config.config.custom_element_config.custom_data,
                            }
                            emit_rectangle = false
                    }
                    if should_render { _clay_add_render_command(render_cmd) }
                }

                if emit_rectangle {
                    _clay_add_render_command(Clay_Render_Command{
                        bounding_box = current_bb,
                        render_data  = {rectangle = Clay_Rectangle_Render_Data{
                            background_color = shared_config_ptr.background_color,
                            corner_radius    = shared_config_ptr.corner_radius,
                        }},
                        user_data    = shared_config_ptr.user_data,
                        id           = current_element.id,
                        z_index      = root.z_index,
                        command_type = .Rectangle,
                    })
                }

                // Initial child alignment
                if !_clay_element_has_config(current_element, .Text) {
                    content_size: Clay_Dimensions
                    if layout_config.layout_direction == .Left_To_Right {
                        for i in 0..<i32(current_element.children_or_text_content.children.length) {
                            child_element := _clay_array_get(&ctx.layout_elements,
                                current_element.children_or_text_content.children.elements[i], &_layout_element_default)
                            content_size.width += child_element.dimensions.width
                            if child_element.dimensions.height > content_size.height { content_size.height = child_element.dimensions.height }
                        }
                        content_size.width += f32(max(i32(current_element.children_or_text_content.children.length) - 1, 0) * i32(layout_config.child_gap))
                        extra_space := current_element.dimensions.width - f32(layout_config.padding.left + layout_config.padding.right) - content_size.width
                        switch layout_config.child_alignment.x {
                            case .Left:   extra_space = 0
                            case .Center: extra_space /= 2
                            case .Right:  // keep as-is
                        }
                        current_tree_node.next_child_offset.x += extra_space
                    } else {
                        for i in 0..<i32(current_element.children_or_text_content.children.length) {
                            child_element := _clay_array_get(&ctx.layout_elements,
                                current_element.children_or_text_content.children.elements[i], &_layout_element_default)
                            if child_element.dimensions.width > content_size.width { content_size.width = child_element.dimensions.width }
                            content_size.height += child_element.dimensions.height
                        }
                        content_size.height += f32(max(i32(current_element.children_or_text_content.children.length) - 1, 0) * i32(layout_config.child_gap))
                        extra_space := current_element.dimensions.height - f32(layout_config.padding.top + layout_config.padding.bottom) - content_size.height
                        switch layout_config.child_alignment.y {
                            case .Top:    extra_space = 0
                            case .Center: extra_space /= 2
                            case .Bottom: // keep as-is
                        }
                        current_tree_node.next_child_offset.y += extra_space
                    }
                    if scroll_container_data != nil {
                        scroll_container_data.content_size = Clay_Dimensions{
                            content_size.width  + f32(layout_config.padding.left + layout_config.padding.right),
                            content_size.height + f32(layout_config.padding.top  + layout_config.padding.bottom),
                        }
                    }
                }
            } else {
                // DFS returning upwards
                close_clip_element := false
                clip_cfg := _clay_find_element_config_with_type(current_element, .Clip).clip_element_config
                if clip_cfg != nil {
                    close_clip_element = true
                    for i in 0..<ctx.scroll_container_datas.length {
                        mapping := _clay_array_get(&ctx.scroll_container_datas, i, &_scroll_container_data_internal_default)
                        if mapping.layout_element == current_element {
                            scroll_offset = clip_cfg.child_offset
                            if ctx.external_scroll_handling_enabled { scroll_offset = {} }
                            break
                        }
                    }
                }

                if _clay_element_has_config(current_element, .Border) {
                    current_element_data := _clay_get_hash_map_item(current_element.id)
                    current_bb := current_element_data.bounding_box
                    if !_clay_element_is_offscreen(&current_bb) {
                        sc := &_shared_element_config_default
                        if _clay_element_has_config(current_element, .Shared) {
                            sc = _clay_find_element_config_with_type(current_element, .Shared).shared_element_config
                        }
                        border_cfg := _clay_find_element_config_with_type(current_element, .Border).border_element_config
                        _clay_add_render_command(Clay_Render_Command{
                            bounding_box = current_bb,
                            render_data  = {border = Clay_Border_Render_Data{
                                color         = border_cfg.color,
                                corner_radius = sc.corner_radius,
                                width         = border_cfg.width,
                            }},
                            user_data    = sc.user_data,
                            id           = _clay_hash_number(current_element.id, u32(current_element.children_or_text_content.children.length)).id,
                            command_type = .Border,
                        })

                        // Between-children borders
                        if border_cfg.width.between_children > 0 && border_cfg.color.a > 0 {
                            half_gap := f32(layout_config.child_gap) / 2
                            border_offset := Clay_Vector2{f32(layout_config.padding.left) - half_gap, f32(layout_config.padding.top) - half_gap}
                            if layout_config.layout_direction == .Left_To_Right {
                                for i in 0..<i32(current_element.children_or_text_content.children.length) {
                                    child_element := _clay_array_get(&ctx.layout_elements,
                                        current_element.children_or_text_content.children.elements[i], &_layout_element_default)
                                    if i > 0 {
                                        _clay_add_render_command(Clay_Render_Command{
                                            bounding_box = {current_bb.x + border_offset.x + scroll_offset.x, current_bb.y + scroll_offset.y, f32(border_cfg.width.between_children), current_element.dimensions.height},
                                            render_data  = {rectangle = {background_color = border_cfg.color}},
                                            user_data    = sc.user_data,
                                            id           = _clay_hash_number(current_element.id, u32(current_element.children_or_text_content.children.length) + 1 + u32(i)).id,
                                            command_type = .Rectangle,
                                        })
                                    }
                                    border_offset.x += child_element.dimensions.width + f32(layout_config.child_gap)
                                }
                            } else {
                                for i in 0..<i32(current_element.children_or_text_content.children.length) {
                                    child_element := _clay_array_get(&ctx.layout_elements,
                                        current_element.children_or_text_content.children.elements[i], &_layout_element_default)
                                    if i > 0 {
                                        _clay_add_render_command(Clay_Render_Command{
                                            bounding_box = {current_bb.x + scroll_offset.x, current_bb.y + border_offset.y + scroll_offset.y, current_element.dimensions.width, f32(border_cfg.width.between_children)},
                                            render_data  = {rectangle = {background_color = border_cfg.color}},
                                            user_data    = sc.user_data,
                                            id           = _clay_hash_number(current_element.id, u32(current_element.children_or_text_content.children.length) + 1 + u32(i)).id,
                                            command_type = .Rectangle,
                                        })
                                    }
                                    border_offset.y += child_element.dimensions.height + f32(layout_config.child_gap)
                                }
                            }
                        }
                    }
                }

                if close_clip_element {
                    _clay_add_render_command(Clay_Render_Command{
                        id           = _clay_hash_number(current_element.id, u32(root_element.children_or_text_content.children.length) + 11).id,
                        command_type = .Scissor_End,
                    })
                }
                dfs_buffer.length -= 1
                continue
            }

            // Add children to DFS buffer
            if !_clay_element_has_config(current_element, .Text) {
                children_len := i32(current_element.children_or_text_content.children.length)
                dfs_buffer.length += children_len
                for i in 0..<children_len {
                    child_element := _clay_array_get(&ctx.layout_elements,
                        current_element.children_or_text_content.children.elements[i], &_layout_element_default)

                    // Off-axis alignment
                    if layout_config.layout_direction == .Left_To_Right {
                        current_tree_node.next_child_offset.y = f32(current_element.layout_config.padding.top)
                        white_space := current_element.dimensions.height - f32(layout_config.padding.top + layout_config.padding.bottom) - child_element.dimensions.height
                        switch layout_config.child_alignment.y {
                            case .Top:
                            case .Center: current_tree_node.next_child_offset.y += white_space / 2
                            case .Bottom: current_tree_node.next_child_offset.y += white_space
                        }
                    } else {
                        current_tree_node.next_child_offset.x = f32(current_element.layout_config.padding.left)
                        white_space := current_element.dimensions.width - f32(layout_config.padding.left + layout_config.padding.right) - child_element.dimensions.width
                        switch layout_config.child_alignment.x {
                            case .Left:
                            case .Center: current_tree_node.next_child_offset.x += white_space / 2
                            case .Right:  current_tree_node.next_child_offset.x += white_space
                        }
                    }

                    child_position := Clay_Vector2{
                        current_tree_node.position.x + current_tree_node.next_child_offset.x + scroll_offset.x,
                        current_tree_node.position.y + current_tree_node.next_child_offset.y + scroll_offset.y,
                    }

                    new_node_index := dfs_buffer.length - 1 - i
                    dfs_buffer.internal_array[new_node_index] = _Clay_Layout_Element_Tree_Node{
                        layout_element    = child_element,
                        position          = child_position,
                        next_child_offset = {f32(child_element.layout_config.padding.left), f32(child_element.layout_config.padding.top)},
                    }
                    ctx.tree_node_visited.internal_array[new_node_index] = false

                    if layout_config.layout_direction == .Left_To_Right {
                        current_tree_node.next_child_offset.x += child_element.dimensions.width + f32(layout_config.child_gap)
                    } else {
                        current_tree_node.next_child_offset.y += child_element.dimensions.height + f32(layout_config.child_gap)
                    }
                }
            }
        }

        if root.clip_element_id != 0 && !ctx.external_scroll_handling_enabled {
            _clay_add_render_command(Clay_Render_Command{
                id           = _clay_hash_number(root_element.id, u32(root_element.children_or_text_content.children.length) + 11).id,
                command_type = .Scissor_End,
            })
        }
    }
}

// Helper for wrapped text line slice access
@(private)
_clay_array_slice_get_impl_wt :: proc(slice: ^_Clay_Wrapped_Text_Line_Array_Slice, index: i32) -> ^_Clay_Wrapped_Text_Line {
    if index >= 0 && index < slice.length {
        return &slice.internal_array[index]
    }
    return &_wrapped_text_line_default
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC SIZING HELPERS (replaces C macros)
// ─────────────────────────────────────────────────────────────────────────────

clay_sizing_fit :: proc(min: f32 = 0, max: f32 = 0) -> Clay_Sizing_Axis {
    return Clay_Sizing_Axis{size = {min_max = {min, max}}, type = .Fit}
}

clay_sizing_grow :: proc(min: f32 = 0, max: f32 = 0) -> Clay_Sizing_Axis {
    return Clay_Sizing_Axis{size = {min_max = {min, max}}, type = .Grow}
}

clay_sizing_fixed :: proc(size: f32) -> Clay_Sizing_Axis {
    return Clay_Sizing_Axis{size = {min_max = {size, size}}, type = .Fixed}
}

clay_sizing_percent :: proc(percent: f32) -> Clay_Sizing_Axis {
    return Clay_Sizing_Axis{size = {percent = percent}, type = .Percent}
}

clay_corner_radius :: proc(radius: f32) -> Clay_Corner_Radius {
    return Clay_Corner_Radius{radius, radius, radius, radius}
}

clay_padding_all :: proc(padding: u16) -> Clay_Padding {
    return Clay_Padding{padding, padding, padding, padding}
}

clay_border_outside :: proc(width: u16) -> Clay_Border_Width {
    return Clay_Border_Width{width, width, width, width, 0}
}

clay_border_all :: proc(width: u16) -> Clay_Border_Width {
    return Clay_Border_Width{width, width, width, width, width}
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC ID HELPERS (replaces C macros)
// ─────────────────────────────────────────────────────────────────────────────

clay_id :: proc(label: string) -> Clay_Element_Id {
    return clay_idi(label, 0)
}

clay_idi :: proc(label: string, index: u32) -> Clay_Element_Id {
    return _clay_hash_string(clay_string(label), index, 0)
}

clay_id_local :: proc(label: string) -> Clay_Element_Id {
    return clay_idi_local(label, 0)
}

clay_idi_local :: proc(label: string, index: u32) -> Clay_Element_Id {
    return _clay_hash_string(clay_string(label), index, _clay_get_parent_element_id())
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC ELEMENT HELPERS
// ─────────────────────────────────────────────────────────────────────────────

// Opens and configures an element. Returns true so callers can write:
//   if clay_element({...}) { defer clay_close_element(); ... }
clay_element :: proc(declaration: Clay_Element_Declaration) -> bool {
    _clay_open_element()
    _clay_configure_open_element(declaration)
    return true
}

clay_open_element :: proc() {
    _clay_open_element()
}

clay_configure_open_element :: proc(declaration: Clay_Element_Declaration) {
    _clay_configure_open_element(declaration)
}

clay_close_element :: proc() {
    _clay_close_element()
}

clay_text :: proc(text: Clay_String, text_config: ^Clay_Text_Element_Config) {
    _clay_open_text_element(text, text_config)
}

// Stores a text config in the arena and returns a pointer to it.
// Equivalent to CLAY_TEXT_CONFIG() macro.
clay_text_config :: proc(config: Clay_Text_Element_Config) -> ^Clay_Text_Element_Config {
    return _clay_store_text_element_config(config)
}

// ─────────────────────────────────────────────────────────────────────────────
// PUBLIC API
// ─────────────────────────────────────────────────────────────────────────────

// Returns the minimum arena memory size required for the current settings.
clay_min_memory_size :: proc() -> u32 {
    fake_context: _Clay_Context
    fake_context.max_element_count = _clay_default_max_element_count
    fake_context.max_measure_text_cache_word_count = _clay_default_max_measure_text_word_cache_count
    if _clay_current_context != nil {
        fake_context.max_element_count = _clay_current_context.max_element_count
        fake_context.max_measure_text_cache_word_count = _clay_current_context.max_measure_text_cache_word_count
    }
    fake_arena := _Clay_Internal_Arena{capacity = max(uint), memory = nil}
    fake_context.internal_arena = fake_arena
    _clay_context_allocate_arena(&fake_context.internal_arena)
    _clay_initialize_persistent_memory(&fake_context)
    _clay_initialize_ephemeral_memory(&fake_context)
    return u32(fake_context.internal_arena.next_allocation) + 128
}

// Creates an arena from pre-allocated memory.
clay_create_arena_with_capacity_and_memory :: proc(capacity: uint, memory: rawptr) -> Clay_Arena {
    return Clay_Arena{capacity = capacity, memory = ([^]u8)(memory)}
}

// Initializes a new Clay context. Call once before using Clay.
clay_initialize :: proc(arena: Clay_Arena, layout_dimensions: Clay_Dimensions, error_handler: Clay_Error_Handler) -> ^_Clay_Context {
    internal_arena := _Clay_Internal_Arena{
        capacity = arena.capacity,
        memory   = arena.memory,
    }
    ctx := _clay_context_allocate_arena(&internal_arena)
    if ctx == nil { return nil }

    old_context := _clay_current_context
    ctx^ = _Clay_Context{
        max_element_count                  = old_context != nil ? old_context.max_element_count : _clay_default_max_element_count,
        max_measure_text_cache_word_count  = old_context != nil ? old_context.max_measure_text_cache_word_count : _clay_default_max_measure_text_word_cache_count,
        error_handler                      = error_handler.error_handler_function != nil ? error_handler : Clay_Error_Handler{error_handler_function = _clay_error_handler_function_default},
        layout_dimensions                  = layout_dimensions,
        internal_arena                     = internal_arena,
    }
    clay_set_current_context(ctx)
    _clay_initialize_persistent_memory(ctx)
    _clay_initialize_ephemeral_memory(ctx)

    // Initialize hash maps
    for i in 0..<ctx.layout_elements_hash_map.capacity {
        ctx.layout_elements_hash_map.internal_array[i] = -1
    }
    for i in 0..<ctx.measure_text_hash_map.capacity {
        ctx.measure_text_hash_map.internal_array[i] = 0
    }
    ctx.measure_text_hash_map_internal.length = 1 // Reserve 0 = "no next"
    return ctx
}

clay_get_current_context :: proc() -> ^_Clay_Context {
    return _clay_current_context
}

clay_set_current_context :: proc(ctx: ^_Clay_Context) {
    _clay_current_context = ctx
}

// Sets the function Clay will call to measure text dimensions.
clay_set_measure_text_function :: proc(
    measure_text_fn: proc(text: Clay_String_Slice, config: ^Clay_Text_Element_Config, user_data: rawptr) -> Clay_Dimensions,
    user_data: rawptr,
) {
    ctx := _clay_current_context
    _clay_measure_text_fn = measure_text_fn
    ctx.measure_text_user_data = user_data
}

// Sets an optional function for external scroll offset queries.
clay_set_query_scroll_offset_function :: proc(
    query_fn: proc(element_id: u32, user_data: rawptr) -> Clay_Vector2,
    user_data: rawptr,
) {
    ctx := _clay_current_context
    _clay_query_scroll_offset_fn = query_fn
    ctx.query_scroll_offset_user_data = user_data
}

clay_set_layout_dimensions :: proc(dimensions: Clay_Dimensions) {
    _clay_current_context.layout_dimensions = dimensions
}

// Updates pointer/mouse state. Call every frame before clay_begin_layout.
clay_set_pointer_state :: proc(position: Clay_Vector2, is_pointer_down: bool) {
    ctx := _clay_current_context
    if ctx.boolean_warnings.max_elements_exceeded { return }

    ctx.pointer_info.position = position
    ctx.pointer_over_ids.length = 0
    dfs_buffer := &ctx.layout_element_children_buffer

    for root_index := ctx.layout_element_tree_roots.length - 1; root_index >= 0; root_index -= 1 {
        dfs_buffer.length = 0
        root := _clay_array_get(&ctx.layout_element_tree_roots, root_index, &_layout_element_tree_root_default)
        _clay_array_add(dfs_buffer, root.layout_element_index, &_i32_default)
        ctx.tree_node_visited.internal_array[0] = false
        found := false

        for dfs_buffer.length > 0 {
            if ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] {
                dfs_buffer.length -= 1
                continue
            }
            ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] = true
            current_element := _clay_array_get(&ctx.layout_elements,
                _clay_array_get_value(dfs_buffer, dfs_buffer.length - 1, 0), &_layout_element_default)
            map_item := _clay_get_hash_map_item(current_element.id)
            clip_element_id := _clay_array_get_value(&ctx.layout_element_clip_element_ids,
                i32(uintptr(current_element) - uintptr(ctx.layout_elements.internal_array)) / size_of(_Clay_Layout_Element), 0)
            clip_item := _clay_get_hash_map_item(u32(clip_element_id))

            if map_item != nil {
                element_box := map_item.bounding_box
                element_box.x -= root.pointer_offset.x
                element_box.y -= root.pointer_offset.y
                if _clay_point_is_inside_rect(position, element_box) &&
                   (clip_element_id == 0 || _clay_point_is_inside_rect(position, clip_item.bounding_box)) {
                    if map_item.on_hover_function != nil {
                        map_item.on_hover_function(map_item.element_id, ctx.pointer_info, map_item.hover_function_user_data)
                    }
                    _clay_array_add(&ctx.pointer_over_ids, map_item.element_id, &_element_id_default)
                    found = true
                    if map_item.id_alias != 0 {
                        _clay_array_add(&ctx.pointer_over_ids, Clay_Element_Id{id = map_item.id_alias}, &_element_id_default)
                    }
                }
                if _clay_element_has_config(current_element, .Text) {
                    dfs_buffer.length -= 1
                    continue
                }
                for i := i32(current_element.children_or_text_content.children.length) - 1; i >= 0; i -= 1 {
                    _clay_array_add(dfs_buffer, current_element.children_or_text_content.children.elements[i], &_i32_default)
                    ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] = false
                }
            } else {
                dfs_buffer.length -= 1
            }
        }

        root_element := _clay_array_get(&ctx.layout_elements, root.layout_element_index, &_layout_element_default)
        if found && _clay_element_has_config(root_element, .Floating) {
            fc := _clay_find_element_config_with_type(root_element, .Floating).floating_element_config
            if fc.pointer_capture_mode == .Capture { break }
        }
    }

    if is_pointer_down {
        if ctx.pointer_info.state == .Pressed_This_Frame {
            ctx.pointer_info.state = .Pressed
        } else if ctx.pointer_info.state != .Pressed {
            ctx.pointer_info.state = .Pressed_This_Frame
        }
    } else {
        if ctx.pointer_info.state == .Released_This_Frame {
            ctx.pointer_info.state = .Released
        } else if ctx.pointer_info.state != .Released {
            ctx.pointer_info.state = .Released_This_Frame
        }
    }
}

// Updates all scroll containers. Call every frame, passing scroll wheel delta.
clay_update_scroll_containers :: proc(enable_drag_scrolling: bool, scroll_delta: Clay_Vector2, delta_time: f32) {
    ctx := _clay_current_context
    is_pointer_active := enable_drag_scrolling &&
        (ctx.pointer_info.state == .Pressed || ctx.pointer_info.state == .Pressed_This_Frame)

    highest_priority_element_index := -1
    highest_priority_scroll_data: ^_Clay_Scroll_Container_Data_Internal = nil

    for i := i32(0); i < ctx.scroll_container_datas.length; i += 1 {
        scroll_data := _clay_array_get(&ctx.scroll_container_datas, i, &_scroll_container_data_internal_default)
        if !scroll_data.open_this_frame {
            _clay_array_remove_swapback(&ctx.scroll_container_datas, i, _scroll_container_data_internal_default)
            i -= 1
            continue
        }
        scroll_data.open_this_frame = false
        hash_map_item := _clay_get_hash_map_item(scroll_data.element_id)
        if hash_map_item == nil || hash_map_item == &_layout_element_hash_map_item_default {
            _clay_array_remove_swapback(&ctx.scroll_container_datas, i, _scroll_container_data_internal_default)
            i -= 1
            continue
        }

        if !is_pointer_active && scroll_data.pointer_scroll_active {
            x_diff := scroll_data.scroll_position.x - scroll_data.scroll_origin.x
            if x_diff < -10 || x_diff > 10 {
                scroll_data.scroll_momentum.x = (scroll_data.scroll_position.x - scroll_data.scroll_origin.x) / (scroll_data.momentum_time * 25)
            }
            y_diff := scroll_data.scroll_position.y - scroll_data.scroll_origin.y
            if y_diff < -10 || y_diff > 10 {
                scroll_data.scroll_momentum.y = (scroll_data.scroll_position.y - scroll_data.scroll_origin.y) / (scroll_data.momentum_time * 25)
            }
            scroll_data.pointer_scroll_active = false
            scroll_data.pointer_origin = {}
            scroll_data.scroll_origin  = {}
            scroll_data.momentum_time  = 0
        }

        scroll_occurred := scroll_delta.x != 0 || scroll_delta.y != 0

        scroll_data.scroll_position.x += scroll_data.scroll_momentum.x
        scroll_data.scroll_momentum.x *= 0.95
        if (scroll_data.scroll_momentum.x > -0.1 && scroll_data.scroll_momentum.x < 0.1) || scroll_occurred {
            scroll_data.scroll_momentum.x = 0
        }
        max_x := max(scroll_data.content_size.width - scroll_data.layout_element.dimensions.width, 0)
        scroll_data.scroll_position.x = clamp(scroll_data.scroll_position.x, -max_x, 0)

        scroll_data.scroll_position.y += scroll_data.scroll_momentum.y
        scroll_data.scroll_momentum.y *= 0.95
        if (scroll_data.scroll_momentum.y > -0.1 && scroll_data.scroll_momentum.y < 0.1) || scroll_occurred {
            scroll_data.scroll_momentum.y = 0
        }
        max_y := max(scroll_data.content_size.height - scroll_data.layout_element.dimensions.height, 0)
        scroll_data.scroll_position.y = clamp(scroll_data.scroll_position.y, -max_y, 0)

        for j in 0..<ctx.pointer_over_ids.length {
            if scroll_data.layout_element.id == _clay_array_get(&ctx.pointer_over_ids, j, &_element_id_default).id {
                highest_priority_element_index = j
                highest_priority_scroll_data   = scroll_data
            }
        }
    }

    if highest_priority_element_index > -1 && highest_priority_scroll_data != nil {
        scroll_element := highest_priority_scroll_data.layout_element
        clip_config := _clay_find_element_config_with_type(scroll_element, .Clip).clip_element_config
        can_scroll_v := clip_config.vertical   && highest_priority_scroll_data.content_size.height > scroll_element.dimensions.height
        can_scroll_h := clip_config.horizontal && highest_priority_scroll_data.content_size.width  > scroll_element.dimensions.width

        if can_scroll_v {
            highest_priority_scroll_data.scroll_position.y += scroll_delta.y * 10
        }
        if can_scroll_h {
            highest_priority_scroll_data.scroll_position.x += scroll_delta.x * 10
        }

        if is_pointer_active {
            highest_priority_scroll_data.scroll_momentum = {}
            if !highest_priority_scroll_data.pointer_scroll_active {
                highest_priority_scroll_data.pointer_origin      = ctx.pointer_info.position
                highest_priority_scroll_data.scroll_origin       = highest_priority_scroll_data.scroll_position
                highest_priority_scroll_data.pointer_scroll_active = true
            } else {
                scroll_dx: f32 = 0; scroll_dy: f32 = 0
                if can_scroll_h {
                    old_x := highest_priority_scroll_data.scroll_position.x
                    highest_priority_scroll_data.scroll_position.x = highest_priority_scroll_data.scroll_origin.x +
                        (ctx.pointer_info.position.x - highest_priority_scroll_data.pointer_origin.x)
                    highest_priority_scroll_data.scroll_position.x = max(
                        min(highest_priority_scroll_data.scroll_position.x, 0),
                        -(highest_priority_scroll_data.content_size.width - highest_priority_scroll_data.bounding_box.width))
                    scroll_dx = highest_priority_scroll_data.scroll_position.x - old_x
                }
                if can_scroll_v {
                    old_y := highest_priority_scroll_data.scroll_position.y
                    highest_priority_scroll_data.scroll_position.y = highest_priority_scroll_data.scroll_origin.y +
                        (ctx.pointer_info.position.y - highest_priority_scroll_data.pointer_origin.y)
                    highest_priority_scroll_data.scroll_position.y = max(
                        min(highest_priority_scroll_data.scroll_position.y, 0),
                        -(highest_priority_scroll_data.content_size.height - highest_priority_scroll_data.bounding_box.height))
                    scroll_dy = highest_priority_scroll_data.scroll_position.y - old_y
                }
                if scroll_dx > -0.1 && scroll_dx < 0.1 && scroll_dy > -0.1 && scroll_dy < 0.1 &&
                   highest_priority_scroll_data.momentum_time > 0.15 {
                    highest_priority_scroll_data.momentum_time = 0
                    highest_priority_scroll_data.pointer_origin  = ctx.pointer_info.position
                    highest_priority_scroll_data.scroll_origin   = highest_priority_scroll_data.scroll_position
                } else {
                    highest_priority_scroll_data.momentum_time += delta_time
                }
            }
        }

        if can_scroll_v {
            max_scroll_y := -(highest_priority_scroll_data.content_size.height - scroll_element.dimensions.height)
            highest_priority_scroll_data.scroll_position.y = max(min(highest_priority_scroll_data.scroll_position.y, 0), max_scroll_y)
        }
        if can_scroll_h {
            max_scroll_x := -(highest_priority_scroll_data.content_size.width - scroll_element.dimensions.width)
            highest_priority_scroll_data.scroll_position.x = max(min(highest_priority_scroll_data.scroll_position.x, 0), max_scroll_x)
        }
    }
}

// Returns the current scroll position of the innermost open scroll container.
clay_get_scroll_offset :: proc() -> Clay_Vector2 {
    ctx := _clay_current_context
    if ctx.boolean_warnings.max_elements_exceeded { return {} }
    open_layout_element := _clay_get_open_layout_element()
    if open_layout_element.id == 0 {
        _clay_generate_id_for_anonymous_element(open_layout_element)
    }
    for i in 0..<ctx.scroll_container_datas.length {
        mapping := _clay_array_get(&ctx.scroll_container_datas, i, &_scroll_container_data_internal_default)
        if mapping.layout_element == open_layout_element {
            return mapping.scroll_position
        }
    }
    return {}
}

// Begins a new layout frame.
clay_begin_layout :: proc() {
    ctx := _clay_current_context
    _clay_initialize_ephemeral_memory(ctx)
    ctx.generation += 1
    ctx.dynamic_element_index = 0

    root_dimensions := ctx.layout_dimensions
    if ctx.debug_mode_enabled {
        root_dimensions.width -= f32(_clay_debug_view_width)
    }
    ctx.boolean_warnings = {}

    _clay_open_element()
    _clay_configure_open_element(Clay_Element_Declaration{
        id     = _clay_hash_string(_clay_string_lit("Clay__RootContainer"), 0, 0),
        layout = {sizing = {
            width  = clay_sizing_fixed(root_dimensions.width),
            height = clay_sizing_fixed(root_dimensions.height),
        }},
    })
    _clay_array_add(&ctx.open_layout_element_stack, i32(0), &_i32_default)
    _clay_array_add(&ctx.layout_element_tree_roots, _Clay_Layout_Element_Tree_Root{layout_element_index = 0}, &_layout_element_tree_root_default)
}

// Ends the layout frame and returns all render commands.
clay_end_layout :: proc() -> []Clay_Render_Command {
    ctx := _clay_current_context
    _clay_close_element()

    elements_exceeded_before_debug := ctx.boolean_warnings.max_elements_exceeded
    if ctx.debug_mode_enabled && !elements_exceeded_before_debug {
        ctx.warnings_enabled = false
        _clay_render_debug_view()
        ctx.warnings_enabled = true
    }

    if ctx.boolean_warnings.max_elements_exceeded {
        msg := _clay_string_lit("Clay Error: Layout elements exceeded Clay max element count")
        _clay_add_render_command(Clay_Render_Command{
            bounding_box = {ctx.layout_dimensions.width / 2 - 59 * 4, ctx.layout_dimensions.height / 2, 0, 0},
            render_data  = {text = Clay_Text_Render_Data{
                string_contents = Clay_String_Slice{length = msg.length, chars = msg.chars, base_chars = msg.chars},
                text_color      = {255, 0, 0, 255},
                font_size       = 16,
            }},
            command_type = .Text,
        })
    } else {
        _clay_calculate_final_layout()
    }

    return ctx.render_commands.internal_array[:ctx.render_commands.length]
}

clay_get_element_id :: proc(id_string: Clay_String) -> Clay_Element_Id {
    return _clay_hash_string(id_string, 0, 0)
}

clay_get_element_id_with_index :: proc(id_string: Clay_String, index: u32) -> Clay_Element_Id {
    return _clay_hash_string(id_string, index, 0)
}

clay_get_element_data :: proc(id: Clay_Element_Id) -> Clay_Element_Data {
    item := _clay_get_hash_map_item(id.id)
    if item == &_layout_element_hash_map_item_default { return {} }
    return Clay_Element_Data{bounding_box = item.bounding_box, found = true}
}

// Returns true if the pointer is currently over the most recently opened element.
clay_hovered :: proc() -> bool {
    ctx := _clay_current_context
    if ctx.boolean_warnings.max_elements_exceeded { return false }
    open_layout_element := _clay_get_open_layout_element()
    if open_layout_element.id == 0 {
        _clay_generate_id_for_anonymous_element(open_layout_element)
    }
    for i in 0..<ctx.pointer_over_ids.length {
        if _clay_array_get(&ctx.pointer_over_ids, i, &_element_id_default).id == open_layout_element.id {
            return true
        }
    }
    return false
}

// Registers a hover callback for the most recently opened element.
clay_on_hover :: proc(
    on_hover_function: proc(element_id: Clay_Element_Id, pointer_data: Clay_Pointer_Data, user_data: uintptr),
    user_data: uintptr,
) {
    ctx := _clay_current_context
    if ctx.boolean_warnings.max_elements_exceeded { return }
    open_layout_element := _clay_get_open_layout_element()
    if open_layout_element.id == 0 {
        _clay_generate_id_for_anonymous_element(open_layout_element)
    }
    hash_map_item := _clay_get_hash_map_item(open_layout_element.id)
    hash_map_item.on_hover_function        = on_hover_function
    hash_map_item.hover_function_user_data = user_data
}

// Returns true if the pointer is over the element with the given ID.
clay_pointer_over :: proc(element_id: Clay_Element_Id) -> bool {
    ctx := _clay_current_context
    for i in 0..<ctx.pointer_over_ids.length {
        if _clay_array_get(&ctx.pointer_over_ids, i, &_element_id_default).id == element_id.id {
            return true
        }
    }
    return false
}

// Returns all element IDs currently under the pointer.
clay_get_pointer_over_ids :: proc() -> []Clay_Element_Id {
    ctx := _clay_current_context
    return ctx.pointer_over_ids.internal_array[:ctx.pointer_over_ids.length]
}

clay_get_scroll_container_data :: proc(id: Clay_Element_Id) -> Clay_Scroll_Container_Data {
    ctx := _clay_current_context
    for i in 0..<ctx.scroll_container_datas.length {
        scroll_data := _clay_array_get(&ctx.scroll_container_datas, i, &_scroll_container_data_internal_default)
        if scroll_data.element_id == id.id {
            clip_cfg := _clay_find_element_config_with_type(scroll_data.layout_element, .Clip).clip_element_config
            if clip_cfg == nil { return {} }
            return Clay_Scroll_Container_Data{
                scroll_position             = &scroll_data.scroll_position,
                scroll_container_dimensions = {scroll_data.bounding_box.width, scroll_data.bounding_box.height},
                content_dimensions          = scroll_data.content_size,
                config                      = clip_cfg^,
                found                       = true,
            }
        }
    }
    return {}
}

clay_set_debug_mode_enabled :: proc(enabled: bool) {
    _clay_current_context.debug_mode_enabled = enabled
}

clay_is_debug_mode_enabled :: proc() -> bool {
    return _clay_current_context.debug_mode_enabled
}

clay_set_culling_enabled :: proc(enabled: bool) {
    _clay_current_context.disable_culling = !enabled
}

clay_set_external_scroll_handling_enabled :: proc(enabled: bool) {
    _clay_current_context.external_scroll_handling_enabled = enabled
}

clay_get_max_element_count :: proc() -> i32 {
    return _clay_current_context.max_element_count
}

clay_set_max_element_count :: proc(max_element_count: i32) {
    ctx := _clay_current_context
    if ctx != nil {
        ctx.max_element_count = max_element_count
    } else {
        _clay_default_max_element_count = max_element_count
        _clay_default_max_measure_text_word_cache_count = max_element_count * 2
    }
}

clay_get_max_measure_text_cache_word_count :: proc() -> i32 {
    return _clay_current_context.max_measure_text_cache_word_count
}

clay_set_max_measure_text_cache_word_count :: proc(max_count: i32) {
    ctx := _clay_current_context
    if ctx != nil {
        ctx.max_measure_text_cache_word_count = max_count
    } else {
        _clay_default_max_measure_text_word_cache_count = max_count
    }
}

clay_reset_measure_text_cache :: proc() {
    ctx := _clay_current_context
    ctx.measure_text_hash_map_internal.length = 0
    ctx.measure_text_hash_map_internal_free_list.length = 0
    ctx.measure_text_hash_map.length = 0
    ctx.measured_words.length = 0
    ctx.measured_words_free_list.length = 0
    for i in 0..<ctx.measure_text_hash_map.capacity {
        ctx.measure_text_hash_map.internal_array[i] = 0
    }
    ctx.measure_text_hash_map_internal.length = 1 // Reserve 0
}

// ─────────────────────────────────────────────────────────────────────────────
// DEBUG VIEW (internal rendering)
// ─────────────────────────────────────────────────────────────────────────────

@(private)
_Clay_Debug_Config_Type_Label :: struct {
    label: Clay_String,
    color: Clay_Color,
}

@(private)
_clay_debug_get_element_config_type_label :: proc(type: _Clay_Element_Config_Type) -> _Clay_Debug_Config_Type_Label {
    switch type {
        case .Shared:   return {_clay_string_lit("Shared"),   {243, 134, 48, 255}}
        case .Text:     return {_clay_string_lit("Text"),     {105, 210, 231, 255}}
        case .Aspect:   return {_clay_string_lit("Aspect"),   {101, 149, 194, 255}}
        case .Image:    return {_clay_string_lit("Image"),    {121, 189, 154, 255}}
        case .Floating: return {_clay_string_lit("Floating"), {250, 105,   0, 255}}
        case .Clip:     return {_clay_string_lit("Scroll"),   {242, 196,  90, 255}}
        case .Border:   return {_clay_string_lit("Border"),   {108,  91, 123, 255}}
        case .Custom:   return {_clay_string_lit("Custom"),   { 11,  72, 107, 255}}
        case .None:     return {_clay_string_lit("Error"),    {  0,   0,   0, 255}}
    }
    return {_clay_string_lit("Error"), {0, 0, 0, 255}}
}

@(private)
_Clay_Debug_Layout_Data :: struct {
    row_count:                  i32,
    selected_element_row_index: i32,
}

@(private)
_clay_open_with :: proc(id: Clay_Element_Id, layout: Clay_Layout_Config, bg: Clay_Color = {}, corner: Clay_Corner_Radius = {}, border: Clay_Border_Element_Config = {}, floating: Clay_Floating_Element_Config = {}) {
    _clay_open_element()
    _clay_configure_open_element(Clay_Element_Declaration{
        id               = id,
        layout           = layout,
        background_color = bg,
        corner_radius    = corner,
        border           = border,
        floating         = floating,
    })
}

@(private)
_clay_close :: proc() {
    _clay_close_element()
}

@(private)
_clay_text_config_lit :: proc(color: Clay_Color, size: u16, wrap: Clay_Text_Wrap_Mode = .None) -> ^Clay_Text_Element_Config {
    return _clay_store_text_element_config(Clay_Text_Element_Config{text_color = color, font_size = size, wrap_mode = wrap})
}

@(private)
_clay_render_debug_layout_elements_list :: proc(initial_roots_length: i32, highlighted_row_index: i32) -> _Clay_Debug_Layout_Data {
    ctx := _clay_current_context
    dfs_buffer := &ctx.reusable_element_index_buffer
    debug_scroll_view_item_layout := Clay_Layout_Config{
        sizing         = {height = clay_sizing_fixed(_CLAY_DEBUGVIEW_ROW_HEIGHT)},
        child_gap      = 6,
        child_alignment = {y = .Center},
    }
    layout_data := _Clay_Debug_Layout_Data{}
    highlighted_element_id: u32 = 0
    name_text_config := _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_4, 16, .None)

    for root_index in 0..<initial_roots_length {
        dfs_buffer.length = 0
        root := _clay_array_get(&ctx.layout_element_tree_roots, root_index, &_layout_element_tree_root_default)
        _clay_array_add(dfs_buffer, root.layout_element_index, &_i32_default)
        ctx.tree_node_visited.internal_array[0] = false

        if root_index > 0 {
            // Empty separator row
            _clay_open_element()
            _clay_configure_open_element(Clay_Element_Declaration{
                id = _clay_hash_string(_clay_string_lit("Clay__DebugView_EmptyRowOuter"), u32(root_index), 0),
                layout = {sizing = {width = clay_sizing_grow()}, padding = {left = _CLAY_DEBUGVIEW_INDENT_WIDTH / 2}},
            })
            _clay_open_element()
            _clay_configure_open_element(Clay_Element_Declaration{
                id = _clay_hash_string(_clay_string_lit("Clay__DebugView_EmptyRow"), u32(root_index), 0),
                layout = {sizing = {width = clay_sizing_grow(), height = clay_sizing_fixed(_CLAY_DEBUGVIEW_ROW_HEIGHT)}},
                border = {color = _CLAY_DEBUGVIEW_COLOR_3, width = {top = 1}},
            })
            _clay_close_element()
            _clay_close_element()
            layout_data.row_count += 1
        }

        for dfs_buffer.length > 0 {
            current_element_index := _clay_array_get_value(dfs_buffer, dfs_buffer.length - 1, 0)
            current_element := _clay_array_get(&ctx.layout_elements, current_element_index, &_layout_element_default)

            if ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] {
                if !_clay_element_has_config(current_element, .Text) && current_element.children_or_text_content.children.length > 0 {
                    _clay_close_element(); _clay_close_element(); _clay_close_element()
                }
                dfs_buffer.length -= 1
                continue
            }

            if highlighted_row_index == layout_data.row_count {
                if ctx.pointer_info.state == .Pressed_This_Frame {
                    ctx.debug_selected_element_id = current_element.id
                }
                highlighted_element_id = current_element.id
            }

            ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] = true
            current_element_data := _clay_get_hash_map_item(current_element.id)
            offscreen := _clay_element_is_offscreen(&current_element_data.bounding_box)

            if ctx.debug_selected_element_id == current_element.id {
                layout_data.selected_element_row_index = layout_data.row_count
            }

            // Row outer
            _clay_open_element()
            _clay_configure_open_element(Clay_Element_Declaration{
                id     = _clay_hash_string(_clay_string_lit("Clay__DebugView_ElementOuter"), current_element.id, 0),
                layout = debug_scroll_view_item_layout,
            })

            // Expand/collapse icon or dot
            if !(_clay_element_has_config(current_element, .Text) || current_element.children_or_text_content.children.length == 0) {
                is_collapsed := current_element_data != nil && current_element_data.debug_data != nil && current_element_data.debug_data.collapsed
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{
                    id            = _clay_hash_string(_clay_string_lit("Clay__DebugView_CollapseElement"), current_element.id, 0),
                    layout        = {sizing = {width = clay_sizing_fixed(16), height = clay_sizing_fixed(16)}, child_alignment = {x = .Center, y = .Center}},
                    corner_radius = clay_corner_radius(4),
                    border        = {color = _CLAY_DEBUGVIEW_COLOR_3, width = clay_border_outside(1)},
                })
                clay_text(is_collapsed ? _clay_string_lit("+") : _clay_string_lit("-"),
                    _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_4, 16))
                _clay_close_element()
            } else {
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{
                    layout = {sizing = {width = clay_sizing_fixed(16), height = clay_sizing_fixed(16)}, child_alignment = {x = .Center, y = .Center}},
                })
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{
                    layout           = {sizing = {width = clay_sizing_fixed(8), height = clay_sizing_fixed(8)}},
                    background_color = _CLAY_DEBUGVIEW_COLOR_3,
                    corner_radius    = clay_corner_radius(2),
                })
                _clay_close_element()
                _clay_close_element()
            }

            // Collision / offscreen badges
            if current_element_data != nil {
                if current_element_data.debug_data != nil && current_element_data.debug_data.collision {
                    _clay_open_element()
                    _clay_configure_open_element(Clay_Element_Declaration{
                        layout = {padding = {8, 8, 2, 2}},
                        border = {color = {177, 147, 8, 255}, width = clay_border_outside(1)},
                    })
                    clay_text(_clay_string_lit("Duplicate ID"), _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_3, 16))
                    _clay_close_element()
                }
                if offscreen {
                    _clay_open_element()
                    _clay_configure_open_element(Clay_Element_Declaration{
                        layout = {padding = {8, 8, 2, 2}},
                        border = {color = _CLAY_DEBUGVIEW_COLOR_3, width = clay_border_outside(1)},
                    })
                    clay_text(_clay_string_lit("Offscreen"), _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_3, 16))
                    _clay_close_element()
                }
            }

            // Element ID string
            id_string := ctx.layout_element_id_strings.internal_array[current_element_index]
            if id_string.length > 0 {
                clay_text(id_string, offscreen ? _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_3, 16) : name_text_config)
            }

            // Element config badges
            for eci in 0..<current_element.element_configs.length {
                element_config := _clay_array_slice_get_impl(&current_element.element_configs, eci)
                if element_config.type == .Shared {
                    sc := element_config.config.shared_element_config
                    badge_color := Clay_Color{243, 134, 48, 90}
                    if sc.background_color.a > 0 {
                        _clay_open_element()
                        _clay_configure_open_element(Clay_Element_Declaration{
                            layout        = {padding = {8, 8, 2, 2}},
                            background_color = badge_color,
                            corner_radius = clay_corner_radius(4),
                            border        = {color = badge_color, width = clay_border_outside(1)},
                        })
                        clay_text(_clay_string_lit("Color"), _clay_text_config_lit(
                            offscreen ? _CLAY_DEBUGVIEW_COLOR_3 : _CLAY_DEBUGVIEW_COLOR_4, 16))
                        _clay_close_element()
                    }
                    continue
                }
                label_cfg := _clay_debug_get_element_config_type_label(element_config.type)
                badge_bg := label_cfg.color; badge_bg.a = 90
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{
                    layout        = {padding = {8, 8, 2, 2}},
                    background_color = badge_bg,
                    corner_radius = clay_corner_radius(4),
                    border        = {color = label_cfg.color, width = clay_border_outside(1)},
                })
                clay_text(label_cfg.label, _clay_text_config_lit(
                    offscreen ? _CLAY_DEBUGVIEW_COLOR_3 : _CLAY_DEBUGVIEW_COLOR_4, 16))
                _clay_close_element()
            }

            // Close row outer
            _clay_close_element()

            // Render text contents row
            if _clay_element_has_config(current_element, .Text) {
                layout_data.row_count += 1
                text_data := current_element.children_or_text_content.text_element_data
                raw_text_config := offscreen ? _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_3, 16) : name_text_config
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{
                    layout = {sizing = {height = clay_sizing_fixed(_CLAY_DEBUGVIEW_ROW_HEIGHT)}, child_alignment = {y = .Center}},
                })
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{
                    layout = {sizing = {width = clay_sizing_fixed(_CLAY_DEBUGVIEW_INDENT_WIDTH + 16)}},
                })
                _clay_close_element()
                clay_text(_clay_string_lit("\""), raw_text_config)
                preview_text := text_data.text
                if preview_text.length > 40 { preview_text.length = 40 }
                clay_text(preview_text, raw_text_config)
                if text_data.text.length > 40 {
                    clay_text(_clay_string_lit("..."), raw_text_config)
                }
                clay_text(_clay_string_lit("\""), raw_text_config)
                _clay_close_element()
            } else if current_element.children_or_text_content.children.length > 0 {
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{layout = {padding = {left = 8}}})
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{
                    layout = {padding = {left = _CLAY_DEBUGVIEW_INDENT_WIDTH}},
                    border = {color = _CLAY_DEBUGVIEW_COLOR_3, width = {left = 1}},
                })
                _clay_open_element()
                _clay_configure_open_element(Clay_Element_Declaration{layout = {layout_direction = .Top_To_Bottom}})
            }

            layout_data.row_count += 1

            collapsed := current_element_data != nil && current_element_data.debug_data != nil && current_element_data.debug_data.collapsed
            if !(_clay_element_has_config(current_element, .Text) || collapsed) {
                for i := i32(current_element.children_or_text_content.children.length) - 1; i >= 0; i -= 1 {
                    _clay_array_add(dfs_buffer, current_element.children_or_text_content.children.elements[i], &_i32_default)
                    ctx.tree_node_visited.internal_array[dfs_buffer.length - 1] = false
                }
            }
        }
    }

    // Handle collapse button clicks
    if ctx.pointer_info.state == .Pressed_This_Frame {
        collapse_button_base_id := _clay_hash_string(_clay_string_lit("Clay__DebugView_CollapseElement"), 0, 0).base_id
        for i := i32(ctx.pointer_over_ids.length) - 1; i >= 0; i -= 1 {
            eid := _clay_array_get(&ctx.pointer_over_ids, i, &_element_id_default)
            if eid.base_id == collapse_button_base_id {
                highlighted_item := _clay_get_hash_map_item(eid.offset)
                if highlighted_item.debug_data != nil {
                    highlighted_item.debug_data.collapsed = !highlighted_item.debug_data.collapsed
                }
                break
            }
        }
    }

    // Highlight hovered element
    if highlighted_element_id != 0 {
        _clay_open_element()
        _clay_configure_open_element(Clay_Element_Declaration{
            id      = _clay_hash_string(_clay_string_lit("Clay__DebugView_ElementHighlight"), 0, 0),
            layout  = {sizing = {width = clay_sizing_grow(), height = clay_sizing_grow()}},
            floating = {
                parent_id            = highlighted_element_id,
                z_index              = 32767,
                pointer_capture_mode = .Passthrough,
                attach_to            = .Element_With_Id,
            },
        })
        _clay_open_element()
        _clay_configure_open_element(Clay_Element_Declaration{
            id               = _clay_hash_string(_clay_string_lit("Clay__DebugView_ElementHighlightRectangle"), 0, 0),
            layout           = {sizing = {width = clay_sizing_grow(), height = clay_sizing_grow()}},
            background_color = _clay_debug_view_highlight_color,
        })
        _clay_close_element()
        _clay_close_element()
    }

    return layout_data
}

@(private)
_clay_render_debug_view :: proc() {
    ctx := _clay_current_context

    close_button_id := _clay_hash_string(_clay_string_lit("Clay__DebugViewTopHeaderCloseButtonOuter"), 0, 0)
    if ctx.pointer_info.state == .Pressed_This_Frame {
        for i in 0..<ctx.pointer_over_ids.length {
            eid := _clay_array_get(&ctx.pointer_over_ids, i, &_element_id_default)
            if eid.id == close_button_id.id {
                ctx.debug_mode_enabled = false
                return
            }
        }
    }

    initial_roots_length := ctx.layout_element_tree_roots.length
    info_text_config  := _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_4, 16, .None)
    info_title_config := _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_3, 16, .None)
    scroll_id := _clay_hash_string(_clay_string_lit("Clay__DebugViewOuterScrollPane"), 0, 0)
    scroll_y_offset: f32 = 0
    pointer_in_debug_view := ctx.pointer_info.position.y < ctx.layout_dimensions.height - 300

    for i in 0..<ctx.scroll_container_datas.length {
        scroll_data := _clay_array_get(&ctx.scroll_container_datas, i, &_scroll_container_data_internal_default)
        if scroll_data.element_id == scroll_id.id {
            scroll_y_offset = scroll_data.scroll_position.y
            break
        }
    }

    highlighted_row_index := i32(-1)
    if pointer_in_debug_view {
        highlighted_row_index = i32((ctx.pointer_info.position.y - scroll_y_offset) / _CLAY_DEBUGVIEW_ROW_HEIGHT)
    }

    // Main debug container
    _clay_open_element()
    _clay_configure_open_element(Clay_Element_Declaration{
        id      = _clay_hash_string(_clay_string_lit("Clay__DebugViewOuter"), 0, 0),
        layout  = {
            sizing        = {width = clay_sizing_fixed(f32(_clay_debug_view_width)), height = clay_sizing_grow()},
            layout_direction = .Top_To_Bottom,
        },
        background_color = _CLAY_DEBUGVIEW_COLOR_2,
        floating = {
            attach_to = .Right,
            z_index   = 32765,
        },
    })

    // Header
    _clay_open_element()
    _clay_configure_open_element(Clay_Element_Declaration{
        id      = _clay_hash_string(_clay_string_lit("Clay__DebugViewTopHeader"), 0, 0),
        layout  = {sizing = {width = clay_sizing_grow(), height = clay_sizing_fixed(40)}, child_alignment = {y = .Center}},
        background_color = _CLAY_DEBUGVIEW_COLOR_1,
    })
    clay_text(_clay_string_lit("Clay Debug Tools"), _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_4, 16))
    _clay_open_element()
    _clay_configure_open_element(Clay_Element_Declaration{layout = {sizing = {width = clay_sizing_grow()}}})
    _clay_close_element()
    // Close button
    _clay_open_element()
    _clay_configure_open_element(Clay_Element_Declaration{
        id      = close_button_id,
        layout  = {sizing = {width = clay_sizing_fixed(40), height = clay_sizing_fixed(40)}, child_alignment = {x = .Center, y = .Center}},
        background_color = {177, 41, 41, 255},
    })
    clay_text(_clay_string_lit("X"), _clay_text_config_lit(_CLAY_DEBUGVIEW_COLOR_4, 16))
    _clay_close_element()
    _clay_close_element() // header

    // Scroll pane
    _clay_open_element()
    _clay_configure_open_element(Clay_Element_Declaration{
        id     = scroll_id,
        layout = {sizing = {width = clay_sizing_grow(), height = clay_sizing_grow()}, layout_direction = .Top_To_Bottom},
        clip   = {vertical = true, child_offset = clay_get_scroll_offset()},
    })
    layout_data := _clay_render_debug_layout_elements_list(i32(initial_roots_length), highlighted_row_index)
    _ = layout_data
    _clay_close_element() // scroll pane

    _clay_close_element() // outer
}