const std = @import("std");
const objc = @import("z3d").platform.macos.objc;
const types = @import("types.zig");

extern "Metal" fn MTLCreateSystemDefaultDevice() ?objc.Id;

const send_clear_color: types.SendClearColorFn = @ptrCast(&objc.objc_msgSend);
const send_size: types.SendSizeFn = @ptrCast(&objc.objc_msgSend);
const send_draw_primitives: types.SendDrawPrimitivesFn = @ptrCast(&objc.objc_msgSend);
const send_new_buffer: types.SendNewBufferFn = @ptrCast(&objc.objc_msgSend);
const send_vertex_buffer: types.SendVertexBufferFn = @ptrCast(&objc.objc_msgSend);
const send_draw_indexed_primitives: types.SendDrawIndexedPrimitivesFn = @ptrCast(&objc.objc_msgSend);
const send_vertex_bytes: types.SendVertexBytesFn = @ptrCast(&objc.objc_msgSend);

pub const Error = error{
    CAMetalLayerCreationFailed,
    TextureCreationFailed,
    MTLDeviceUnavailable,
    CommandQueueCreationFailed,
    RenderPipelineStateCreationFailed,
    CommandBufferCreationFailed,
    RenderEncoderCreationFailed,
    RenderPassCreationFailed,
    ColorAttachmentsUnavailable,
    ColorAttachmentUnavailable,
    PipelineColorAttachmentUnavailable,
    RenderPipelineDescriptorCreationFailed,
    PipelineColorAttachmentsUnavailable,
    LibraryCreationFailed,
    MTLBufferCreationFailed,
};

pub const CAMetalLayer = struct {
    metal_layer: objc.Id,
    set_device_sel: objc.Sel,
    next_drawable_sel: objc.Sel,
    set_drawable_size_sel: objc.Sel,

    const Self = @This();

    pub fn init() !Self {
        const metal_layer_class = objc.objc_getClass("CAMetalLayer") orelse
            return objc.Error.ClassUnavailable;

        const layer_sel = objc.sel_registerName("layer") orelse
            return objc.Error.SelectorUnavailable;
        const metal_layer = objc.send(metal_layer_class, layer_sel) orelse
            return Error.CAMetalLayerCreationFailed;

        const set_device_sel = objc.sel_registerName("setDevice:") orelse
            return objc.Error.SelectorUnavailable;
        const next_drawable_sel = objc.sel_registerName("nextDrawable") orelse
            return objc.Error.SelectorUnavailable;
        const set_drawable_size_sel = objc.sel_registerName("setDrawableSize:") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .metal_layer = metal_layer,
            .set_device_sel = set_device_sel,
            .next_drawable_sel = next_drawable_sel,
            .set_drawable_size_sel = set_drawable_size_sel,
        };
    }

    pub fn setDevice(self: *const Self, device: MTLDevice) void {
        objc.send_object(self.metal_layer, self.set_device_sel, device.device);
    }

    pub fn nextDrawable(self: *const Self) !?CAMetalDrawable {
        const drawable = objc.send(
            self.metal_layer,
            self.next_drawable_sel,
        ) orelse return null;

        return try CAMetalDrawable.init(drawable);
    }

    pub fn setDrawableSize(
        self: *const Self,
        width: f64,
        height: f64,
    ) void {
        send_size(self.metal_layer, self.set_drawable_size_sel, .{
            .width = width,
            .height = height,
        });
    }
};

pub const CAMetalDrawable = struct {
    drawable: objc.Id,
    texture_sel: objc.Sel,

    const Self = @This();

    pub fn init(drawable: objc.Id) !Self {
        const texture_sel = objc.sel_registerName("texture") orelse
            return objc.Error.SelectorUnavailable;

        return .{ .drawable = drawable, .texture_sel = texture_sel };
    }

    pub fn texture(self: *const Self) !MTLTexture {
        const t = objc.send(self.drawable, self.texture_sel) orelse
            return Error.TextureCreationFailed;

        return MTLTexture.init(t);
    }
};

pub const MTLDevice = struct {
    device: objc.Id,
    new_queue_sel: objc.Sel,
    new_render_pipeline_state_sel: objc.Sel,
    new_buffer_with_bytes_sel: objc.Sel,

    const Self = @This();

    pub fn init() !Self {
        const device = MTLCreateSystemDefaultDevice() orelse
            return Error.MTLDeviceUnavailable;

        const new_queue_sel = objc.sel_registerName("newCommandQueue") orelse
            return objc.Error.SelectorUnavailable;
        const new_render_pipeline_state_sel = objc.sel_registerName(
            "newRenderPipelineStateWithDescriptor:error:",
        ) orelse return objc.Error.SelectorUnavailable;
        const new_buffer_with_bytes_sel = objc.sel_registerName(
            "newBufferWithBytes:length:options:",
        ) orelse return objc.Error.SelectorUnavailable;

        return .{
            .device = device,
            .new_queue_sel = new_queue_sel,
            .new_render_pipeline_state_sel = new_render_pipeline_state_sel,
            .new_buffer_with_bytes_sel = new_buffer_with_bytes_sel,
        };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.device);
    }

    pub fn newCommandQueue(self: *const Self) !MTLCommandQueue {
        const command_queue = objc.send(self.device, self.new_queue_sel) orelse
            return Error.CommandQueueCreationFailed;

        return try MTLCommandQueue.init(command_queue);
    }

    pub fn newRenderPipelineState(
        self: *const Self,
        descriptor: MTLRenderPipelineDescriptor,
    ) !MTLRenderPipelineState {
        var ns_error: ?objc.Id = null;

        const pipeline = objc.send_object_error(
            self.device,
            self.new_render_pipeline_state_sel,
            descriptor.descriptor,
            &ns_error,
        ) orelse {
            if (ns_error) |err| {
                // TODO: Extract NSError.localizedDescription
                std.debug.print("Metal pipeline error: {*}\n", .{err});
            }

            return Error.RenderPipelineStateCreationFailed;
        };

        return MTLRenderPipelineState.init(pipeline);
    }

    pub fn newBuffer(
        self: *const Self,
        data: []const u8,
    ) !MTLBuffer {
        const buffer = send_new_buffer(
            self.device,
            self.new_buffer_with_bytes_sel,
            data.ptr,
            data.len,
            0,
        ) orelse return Error.MTLBufferCreationFailed;

        return MTLBuffer.init(buffer);
    }
};

pub const MTLBuffer = struct {
    buffer: objc.Id,

    const Self = @This();

    pub fn init(buffer: objc.Id) Self {
        return .{ .buffer = buffer };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.buffer);
    }
};

pub const MTLCommandQueue = struct {
    command_queue: objc.Id,
    cmd_buffer_sel: objc.Sel,

    const Self = @This();

    pub fn init(command_queue: objc.Id) !Self {
        const cmd_buffer_sel = objc.sel_registerName("commandBuffer") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .command_queue = command_queue,
            .cmd_buffer_sel = cmd_buffer_sel,
        };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.command_queue);
    }

    pub fn commandBuffer(self: *const Self) !MTLCommandBuffer {
        const buffer = objc.send(self.command_queue, self.cmd_buffer_sel) orelse
            return Error.CommandBufferCreationFailed;

        return try MTLCommandBuffer.init(buffer);
    }
};

pub const MTLCommandBuffer = struct {
    buffer: objc.Id,
    render_cmd_encoder_with_desc_sel: objc.Sel,
    present_drawable_sel: objc.Sel,
    commit_sel: objc.Sel,

    const Self = @This();

    pub fn init(buffer: objc.Id) !Self {
        const render_cmd_encoder_with_desc_sel = objc.sel_registerName(
            "renderCommandEncoderWithDescriptor:",
        ) orelse return objc.Error.SelectorUnavailable;

        const present_drawable_sel = objc.sel_registerName("presentDrawable:") orelse
            return objc.Error.SelectorUnavailable;

        const commit_sel = objc.sel_registerName("commit") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .buffer = buffer,
            .render_cmd_encoder_with_desc_sel = render_cmd_encoder_with_desc_sel,
            .present_drawable_sel = present_drawable_sel,
            .commit_sel = commit_sel,
        };
    }

    pub fn renderCommandEncoder(
        self: *const Self,
        descriptor: MTLRenderPassDescriptor,
    ) !MTLRenderCommandEncoder {
        const encoder = objc.send_object_return(
            self.buffer,
            self.render_cmd_encoder_with_desc_sel,
            descriptor.descriptor,
        ) orelse return Error.RenderEncoderCreationFailed;

        return try MTLRenderCommandEncoder.init(encoder);
    }

    pub fn presentDrawable(
        self: *const Self,
        drawable: CAMetalDrawable,
    ) void {
        objc.send_object(self.buffer, self.present_drawable_sel, drawable.drawable);
    }

    pub fn commit(self: *const Self) void {
        objc.send_void(self.buffer, self.commit_sel);
    }
};

pub const MTLRenderCommandEncoder = struct {
    encoder: objc.Id,
    end_edncoding_sel: objc.Sel,
    set_render_pipeline_state_sel: objc.Sel,
    draw_primitives_sel: objc.Sel,
    set_vertex_buffer_sel: objc.Sel,
    draw_indexed_primitives_sel: objc.Sel,
    set_vertex_bytes_sel: objc.Sel,

    const Self = @This();

    pub fn init(encoder: objc.Id) !Self {
        const end_edncoding_sel = objc.sel_registerName("endEncoding") orelse
            return objc.Error.SelectorUnavailable;
        const set_render_pipeline_state_sel = objc.sel_registerName(
            "setRenderPipelineState:",
        ) orelse return objc.Error.SelectorUnavailable;
        const draw_primitives_sel = objc.sel_registerName(
            "drawPrimitives:vertexStart:vertexCount:",
        ) orelse return objc.Error.SelectorUnavailable;
        const set_vertex_buffer_sel = objc.sel_registerName(
            "setVertexBuffer:offset:atIndex:",
        ) orelse return objc.Error.SelectorUnavailable;
        const draw_indexed_primitives_sel = objc.sel_registerName(
            "drawIndexedPrimitives:indexCount:indexType:indexBuffer:indexBufferOffset:",
        ) orelse return objc.Error.SelectorUnavailable;
        const set_vertex_bytes_sel = objc.sel_registerName(
            "setVertexBytes:length:atIndex:",
        ) orelse return objc.Error.SelectorUnavailable;

        return .{
            .encoder = encoder,
            .end_edncoding_sel = end_edncoding_sel,
            .set_render_pipeline_state_sel = set_render_pipeline_state_sel,
            .draw_primitives_sel = draw_primitives_sel,
            .set_vertex_buffer_sel = set_vertex_buffer_sel,
            .draw_indexed_primitives_sel = draw_indexed_primitives_sel,
            .set_vertex_bytes_sel = set_vertex_bytes_sel,
        };
    }

    pub fn endEncoding(self: *const Self) void {
        objc.send_void(self.encoder, self.end_edncoding_sel);
    }

    pub fn setRenderPipelineState(
        self: *const Self,
        pipeline: MTLRenderPipelineState,
    ) void {
        objc.send_object(
            self.encoder,
            self.set_render_pipeline_state_sel,
            pipeline.pipeline,
        );
    }

    pub fn drawPrimitives(
        self: *const Self,
        primitive: types.MTLPrimitiveType,
        vertex_start: usize,
        vertex_count: usize,
    ) void {
        send_draw_primitives(
            self.encoder,
            self.draw_primitives_sel,
            @backingInt(primitive),
            vertex_start,
            vertex_count,
        );
    }

    pub fn setVertexBuffer(
        self: *const Self,
        buffer: MTLBuffer,
        offset: usize,
        index: usize,
    ) void {
        send_vertex_buffer(
            self.encoder,
            self.set_vertex_buffer_sel,
            buffer.buffer,
            offset,
            index,
        );
    }

    pub fn drawIndexedPrimitives(
        self: *const Self,
        primitive: types.MTLPrimitiveType,
        index_count: usize,
        index_type: types.MTLIndexType,
        index_buffer: MTLBuffer,
        offset: usize,
    ) void {
        send_draw_indexed_primitives(
            self.encoder,
            self.draw_indexed_primitives_sel,
            @backingInt(primitive),
            index_count,
            @backingInt(index_type),
            index_buffer.buffer,
            offset,
        );
    }

    pub fn setVertexBytes(
        self: *const Self,
        data: []const u8,
        index: usize,
    ) void {
        send_vertex_bytes(
            self.encoder,
            self.set_vertex_bytes_sel,
            data.ptr,
            data.len,
            index,
        );
    }
};

pub const MTLTexture = struct {
    texture: objc.Id,

    const Self = @This();

    pub fn init(texture: objc.Id) Self {
        return .{ .texture = texture };
    }
};

pub const MTLRenderPassDescriptor = struct {
    descriptor: objc.Id,
    color_attachments_sel: objc.Sel,

    const Self = @This();

    pub fn init() !Self {
        const render_pass_class = objc.objc_getClass("MTLRenderPassDescriptor") orelse
            return objc.Error.ClassUnavailable;

        const descriptor_sel = objc.sel_registerName("renderPassDescriptor") orelse
            return objc.Error.SelectorUnavailable;

        const descriptor = objc.send(render_pass_class, descriptor_sel) orelse
            return Error.RenderPassCreationFailed;

        const color_attachements_sel = objc.sel_registerName("colorAttachments") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .descriptor = descriptor,
            .color_attachments_sel = color_attachements_sel,
        };
    }

    pub fn colorAttachments(self: *const Self) !MTLRenderPassColorAttachmentDescriptorArray {
        const attachments = objc.send(self.descriptor, self.color_attachments_sel) orelse
            return Error.ColorAttachmentsUnavailable;

        return MTLRenderPassColorAttachmentDescriptorArray.init(attachments);
    }
};

pub const MTLRenderPassColorAttachmentDescriptorArray = struct {
    attachments: objc.Id,
    index_sel: objc.Sel,

    const Self = @This();

    pub fn init(attachments: objc.Id) !Self {
        const index_sel = objc.sel_registerName("objectAtIndexedSubscript:") orelse
            return objc.Error.SelectorUnavailable;
        return .{
            .attachments = attachments,
            .index_sel = index_sel,
        };
    }

    pub fn sub(self: *const Self, idx: usize) !MTLRenderPassColorAttachmentDescriptor {
        const attachment = objc.send_index(
            self.attachments,
            self.index_sel,
            idx,
        ) orelse return Error.ColorAttachmentUnavailable;

        return try MTLRenderPassColorAttachmentDescriptor.init(attachment);
    }
};

pub const MTLRenderPassColorAttachmentDescriptor = struct {
    attachment: objc.Id,
    set_texture_sel: objc.Sel,
    set_load_action_sel: objc.Sel,
    set_store_action_sel: objc.Sel,
    set_clear_color_sel: objc.Sel,

    const Self = @This();

    pub fn init(attachment: objc.Id) !Self {
        const set_texture_sel = objc.sel_registerName("setTexture:") orelse
            return objc.Error.SelectorUnavailable;

        const set_load_action_sel = objc.sel_registerName("setLoadAction:") orelse
            return objc.Error.SelectorUnavailable;

        const set_store_action_sel = objc.sel_registerName("setStoreAction:") orelse
            return objc.Error.SelectorUnavailable;

        const set_clear_color_sel = objc.sel_registerName("setClearColor:") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .attachment = attachment,
            .set_texture_sel = set_texture_sel,
            .set_load_action_sel = set_load_action_sel,
            .set_store_action_sel = set_store_action_sel,
            .set_clear_color_sel = set_clear_color_sel,
        };
    }

    pub fn setTexture(self: *const Self, texture: MTLTexture) void {
        objc.send_object(self.attachment, self.set_texture_sel, texture.texture);
    }

    pub fn setLoadAction(self: *const Self, action: types.MTLLoadAction) void {
        objc.send_usize(self.attachment, self.set_load_action_sel, @backingInt(action));
    }

    pub fn setStoreAction(self: *const Self, action: types.MTLStoreAction) void {
        objc.send_usize(self.attachment, self.set_store_action_sel, @backingInt(action));
    }

    pub fn setClearColor(self: *const Self, color: types.MTLClearColor) void {
        send_clear_color(
            self.attachment,
            self.set_clear_color_sel,
            color,
        );
    }
};

pub const MTLRenderPipelineColorAttachmentDescriptorArray = struct {
    attachments: objc.Id,
    index_sel: objc.Sel,

    const Self = @This();

    pub fn init(attachments: objc.Id) !Self {
        const index_sel = objc.sel_registerName("objectAtIndexedSubscript:") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .attachments = attachments,
            .index_sel = index_sel,
        };
    }

    pub fn sub(self: *const Self, idx: usize) !MTLRenderPipelineColorAttachmentDescriptor {
        const attachment = objc.send_index(
            self.attachments,
            self.index_sel,
            idx,
        ) orelse return Error.PipelineColorAttachmentUnavailable;

        return try MTLRenderPipelineColorAttachmentDescriptor.init(attachment);
    }
};

pub const MTLRenderPipelineColorAttachmentDescriptor = struct {
    attachment: objc.Id,
    set_pixel_format_sel: objc.Sel,

    const Self = @This();

    pub fn init(attachment: objc.Id) !Self {
        const set_pixel_format_sel = objc.sel_registerName("setPixelFormat:") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .attachment = attachment,
            .set_pixel_format_sel = set_pixel_format_sel,
        };
    }

    pub fn setPixelFormat(self: *const Self, format: types.MTLPixelFormat) void {
        objc.send_usize(
            self.attachment,
            self.set_pixel_format_sel,
            @backingInt(format),
        );
    }
};

pub const MTLRenderPipelineDescriptor = struct {
    descriptor: objc.Id,
    set_vertex_function_sel: objc.Sel,
    set_fragment_function_sel: objc.Sel,
    color_attachments_sel: objc.Sel,

    const Self = @This();

    pub fn init() !Self {
        const cls = objc.objc_getClass("MTLRenderPipelineDescriptor") orelse
            return objc.Error.ClassUnavailable;

        const alloc_sel = objc.sel_registerName("alloc") orelse
            return objc.Error.SelectorUnavailable;

        const init_sel = objc.sel_registerName("init") orelse
            return objc.Error.SelectorUnavailable;

        const allocated = objc.send(cls, alloc_sel) orelse
            return Error.RenderPipelineDescriptorCreationFailed;

        const descriptor = objc.send(allocated, init_sel) orelse
            return Error.RenderPipelineDescriptorCreationFailed;
        errdefer objc.release(descriptor);

        const set_vertex_function_sel = objc.sel_registerName("setVertexFunction:") orelse
            return objc.Error.SelectorUnavailable;

        const set_fragment_function_sel = objc.sel_registerName("setFragmentFunction:") orelse
            return objc.Error.SelectorUnavailable;

        const color_attachments_sel = objc.sel_registerName("colorAttachments") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .descriptor = descriptor,
            .set_vertex_function_sel = set_vertex_function_sel,
            .set_fragment_function_sel = set_fragment_function_sel,
            .color_attachments_sel = color_attachments_sel,
        };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.descriptor);
    }

    pub fn setVertexFunction(self: *const Self, function: MTLFunction) void {
        objc.send_object(self.descriptor, self.set_vertex_function_sel, function.function);
    }

    pub fn setFragmentFunction(self: *const Self, function: MTLFunction) void {
        objc.send_object(self.descriptor, self.set_fragment_function_sel, function.function);
    }

    pub fn colorAttachments(self: *const Self) !MTLRenderPipelineColorAttachmentDescriptorArray {
        const attachments = objc.send(self.descriptor, self.color_attachments_sel) orelse
            return Error.PipelineColorAttachmentsUnavailable;

        return MTLRenderPipelineColorAttachmentDescriptorArray.init(attachments);
    }
};

pub const MTLRenderPipelineState = struct {
    pipeline: objc.Id,

    const Self = @This();

    pub fn init(pipeline: objc.Id) Self {
        return .{ .pipeline = pipeline };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.pipeline);
    }
};

pub const MTLLibrary = struct {
    library: objc.Id,
    new_function_with_name_sel: objc.Sel,

    const Self = @This();

    pub fn init(
        device: MTLDevice,
        path: [*:0]const u8,
    ) !Self {
        const selector = objc.sel_registerName("newLibraryWithFile:error:") orelse
            return objc.Error.SelectorUnavailable;

        const ns_path = try objc.nsString(path);

        var ns_error: ?objc.NsError = null;

        const library = objc.send_object_error(
            device.device,
            selector,
            ns_path,
            &ns_error,
        ) orelse {
            if (ns_error) |err| {
                // TODO: Extract NSError.localizedDescription
                std.debug.print("Metal library creation error: {*}\n", .{err});
            }

            return Error.LibraryCreationFailed;
        };

        const new_function_with_name_sel = objc.sel_registerName("newFunctionWithName:") orelse
            return objc.Error.SelectorUnavailable;

        return .{
            .library = library,
            .new_function_with_name_sel = new_function_with_name_sel,
        };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.library);
    }

    pub fn newFunctionWithName(
        self: *const Self,
        name: [*:0]const u8,
    ) !MTLFunction {
        const ns_name = try objc.nsString(name);

        const function = objc.send_object_return(
            self.library,
            self.new_function_with_name_sel,
            ns_name,
        ) orelse return error.FunctionCreationFailed;

        return MTLFunction.init(function);
    }
};

pub const MTLFunction = struct {
    function: objc.Id,

    const Self = @This();

    pub fn init(function: objc.Id) Self {
        return .{ .function = function };
    }

    pub fn deinit(self: *const Self) void {
        objc.release(self.function);
    }
};
