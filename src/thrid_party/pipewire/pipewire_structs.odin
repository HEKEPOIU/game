package pipewire

import "core:c"

properties :: struct {
    dict:  spa_dict,
    flags: u32,
}


thread_loop_events :: struct {
    version: u32,

    /** the loop is destroyed */
    destroy: proc "c" (data: rawptr),
} // [TODO] fill out fields

loop :: struct {
    system:  ^spa_system,
    loop:    ^spa_loop,
    control: ^spa_loop_control,
    utils:   ^spa_loop_utils,
    name:    cstring,
}


pw_map :: struct {
    items:     array,
    free_list: u32,
}

array :: struct {
    data:   rawptr,
    size:   uint,
    alloc:  uint,
    extend: uint,
}



metadata_events :: struct {
    version:  u32,
    destroy:  proc(data: rawptr),
    free:     proc(data: rawptr),
    property: proc(data: rawptr, subject: u32, key, type, value: cstring) -> c.int,
}


impl_module_events :: struct {
    version:     u32,
    destroy:     proc "c" (data: rawptr),
    free:        proc "c" (data: rawptr),
    initialized: proc "c" (data: rawptr),
    registered:  proc "c" (data: rawptr),
}

module_info :: struct {
    id:          u32,
    name:        cstring,
    filename:    cstring,
    args:        cstring,
    change_mask: Module_Change_Mask_Set,
    props:       spa_dict,
}


Module_Change_Mask_Set :: bit_set[Module_Change_Mask]
Module_Change_Mask :: enum u64 {
    PROPS = 1 << 0,
    ALL   = (1 << 1) - 1,
}

Core_Change_Mask_Set :: bit_set[Core_Change_Mask]
Core_Change_Mask :: enum u64 {
    PROPS = 1 << 0,
    ALL   = (1 << 1) - 1,
}



stream_state :: enum c.int {
    PW_STREAM_STATE_ERROR       = -1,
    PW_STREAM_STATE_UNCONNECTED = 0,
    PW_STREAM_STATE_CONNECTING  = 1,
    PW_STREAM_STATE_PAUSED      = 2,
    PW_STREAM_STATE_STREAMING   = 3,
}

VERSION_REGISTRY_EVENTS :: 0
registry_events :: struct {
    version:       u32,
    /**
	 * Notify of a new global object
	 *
	 * The registry emits this event when a new global object is
	 * available.
	 *
	 * \param id the global object id
	 * \param permissions the permissions of the object
	 * \param type the type of the interface
	 * \param version the version of the interface
	 * \param props extra properties of the global
	 */
    global:    proc "c" (
        data: rawptr,
        id: u32,
        permissions: u32,
        type: cstring,
        version: u32,
        props: ^spa_dict,
    ),
    /**
	 * Notify of a global object removal
	 *
	 * Emitted when a global object was removed from the registry.
	 * If the client has any bindings to the global, it should destroy
	 * those.
	 *
	 * \param id the id of the global that was removed
	 */
    global_remove: proc "c" (data: rawptr, id: u32),
}

registry_methods :: struct {
    version:      u32,
    add_listener: proc "c" (
        object: rawptr,
        listener: ^spa_hook,
        events: ^registry_events,
        data: rawptr,
    ) -> c.int,
    /**
	 * Bind to a global object
	 *
	 * Bind to the global object with \a id and use the client proxy
	 * with new_id as the proxy. After this call, methods can be
	 * send to the remote global object and events can be received
	 *
	 * \param id the global id to bind to
	 * \param type the interface type to bind to
	 * \param version the interface version to use
	 * \returns the new object
	 */
    bind:         proc "c" (
        object: rawptr,
        id: u32,
        type: cstring,
        version: u32,
        use_data_size: c.size_t,
    ) -> rawptr,
    /**
	 * Attempt to destroy a global object
	 *
	 * Try to destroy the global object.
	 *
	 * \param id the global id to destroy. The client needs X permissions
	 * on the global.
	 */
    destroy:      proc "c" (object: rawptr, id: u32) -> c.int,
}


proxy_events :: struct {
    version:     u32,
    destroy:     proc(data: rawptr),
    /** a proxy is bound to a global id */
    bound:       proc(data: rawptr, global_id: u32),
    /** a proxy is removed from the server. Use proxy_destroy to
	 * free the proxy. */
    removed:     proc(data: rawptr),
    /** a reply to a sync method completed */
    done:        proc(data: rawptr, seq: c.int),
    /** an error occurred on the proxy */
    error:       proc(data: rawptr, seq: c.int, res: c.int, message: cstring),
    bound_props: proc(data: rawptr, global_id: u32, props: ^spa_dict),
}


core_events :: struct {
    version:     u32,
    /**
	 * Notify new core info
	 *
	 * This event is emitted when first bound to the core or when the
	 * hello method is called.
	 *
	 * \param info new core info
	 */
    info:        proc "c" (data: rawptr, info: ^core_info),
    /**
	 * Emit a done event
	 *
	 * The done event is emitted as a result of a sync method with the
	 * same seq number.
	 *
	 * \param seq the seq number passed to the sync method call
	 */
    done:        proc "c" (data: rawptr, id: u32, seq: c.int),
    /** Emit a ping event
	 *
	 * The client should reply with a pong reply with the same seq
	 * number.
	 */
    ping:        proc "c" (data: rawptr, id: u32, seq: c.int),
    /**
	 * Fatal error event
         *
         * The error event is sent out when a fatal (non-recoverable)
         * error has occurred. The id argument is the proxy object where
         * the error occurred, most often in response to a request to that
         * object. The message is a brief description of the error,
         * for (debugging) convenience.
	 *
	 * This event is usually also emitted on the proxy object with
	 * \a id.
	 *
         * \param id object where the error occurred
         * \param seq the sequence number that generated the error
         * \param res error code
         * \param message error description
	 */
    error:       proc "c" (data: rawptr, id: u32, seq: c.int, res: c.int, message: cstring),
    /**
	 * Remove an object ID
         *
         * This event is used internally by the object ID management
         * logic. When a client deletes an object, the server will send
         * this event to acknowledge that it has seen the delete request.
         * When the client receives this event, it will know that it can
         * safely reuse the object ID.
	 *
         * \param id deleted object ID
	 */
    remove_id:   proc "c" (data: rawptr, id: u32),
    /**
	 * Notify an object binding
	 *
	 * This event is emitted when a local object ID is bound to a
	 * global ID. It is emitted before the global becomes visible in the
	 * registry.
	 *
	 * The bound_props event is an enhanced version of this event that
	 * also contains the extra global properties.
	 *
	 * \param id bound object ID
	 * \param global_id the global id bound to
	 */
    bound_id:    proc "c" (data: rawptr, id: u32, global_id: u32),
    /**
	 * Add memory for a client
	 *
	 * Memory is given to a client as \a fd of a certain
	 * memory \a type.
	 *
	 * Further references to this fd will be made with the per memory
	 * unique identifier \a id.
	 *
	 * \param id the unique id of the memory
	 * \param type the memory type, one of enum spa_data_type
	 * \param fd the file descriptor
	 * \param flags extra flags
	 */
    add_mem:     proc "c" (data: rawptr, id: u32, type: u32, fd: c.int, flags: u32),
    /**
	 * Remove memory for a client
	 *
	 * \param id the memory id to remove
	 */
    remove_mem:  proc "c" (data: rawptr, id: u32),
    /**
	 * Notify an object binding
	 *
	 * This event is emitted when a local object ID is bound to a
	 * global ID. It is emitted before the global becomes visible in the
	 * registry.
	 *
	 * This is an enhanced version of the bound_id event.
	 *
	 * \param id bound object ID
	 * \param global_id the global id bound to
	 * \param props The properties of the new global object.
	 *
	 * Since version 4:1
	 */
    bound_props: proc "c" (data: rawptr, id: u32, global_id: u32, props: ^spa_dict),
}

core_methods :: struct {
    version:       u32,
    add_listener:  proc "c" (
        object: rawptr,
        listener: ^spa_hook,
        events: ^core_events,
        data: rawptr,
    ) -> c.int,
    /**
	 * Start a conversation with the server. This will send
	 * the core info and will destroy all resources for the client
	 * (except the core and client resource).
	 *
	 * This requires X permissions on the core.
	 */
    hello:         proc "c" (object: rawptr, version: u32) -> c.int,
    /**
	 * Do server roundtrip
	 *
	 * Ask the server to emit the 'done' event with \a seq.
	 *
	 * Since methods are handled in-order and events are delivered
	 * in-order, this can be used as a barrier to ensure all previous
	 * methods and the resulting events have been handled.
	 *
	 * \param seq the seq number passed to the done event
	 *
	 * This requires X permissions on the core.
	 */
    sync:          proc "c" (object: rawptr, id: u32, seq: c.int) -> c.int,
    /**
	 * Reply to a server ping event.
	 *
	 * Reply to the server ping event with the same seq.
	 *
	 * \param seq the seq number received in the ping event
	 *
	 * This requires X permissions on the core.
	 */
    pong:          proc "c" (object: rawptr, id: u32, seq: c.int) -> c.int,
    /**
	 * Fatal error event
         *
         * The error method is sent out when a fatal (non-recoverable)
         * error has occurred. The id argument is the proxy object where
         * the error occurred, most often in response to an event on that
         * object. The message is a brief description of the error,
         * for (debugging) convenience.
	 *
	 * This method is usually also emitted on the resource object with
	 * \a id.
	 *
         * \param id resource id where the error occurred
         * \param res error code
         * \param message error description
	 *
	 * This requires X permissions on the core.
	 */
    error:         proc "c" (
        object: rawptr,
        id: u32,
        seq: c.int,
        res: c.int,
        message: cstring,
    ) -> c.int,
    /**
	 * Get the registry object
	 *
	 * Create a registry object that allows the client to list and bind
	 * the global objects available from the PipeWire server
	 * \param version the client version
	 * \param user_data_size extra size
	 *
	 * This requires X permissions on the core.
	 */
    get_registry:  proc "c" (object: rawptr, version: u32, user_data_size: c.uint) -> ^registry,

    /**
	 * Create a new object on the PipeWire server from a factory.
	 *
	 * \param factory_name the factory name to use
	 * \param type the interface to bind to
	 * \param version the version of the interface
	 * \param props extra properties
	 * \param user_data_size extra size
	 *
	 * This requires X permissions on the core.
	 */
    create_object: proc "c" (
        object: rawptr,
        factory_name: cstring,
        type: cstring,
        version: u32,
        props: ^spa_dict,
        user_data_size: c.uint,
    ) -> rawptr,
    /**
	 * Destroy an resource
	 *
	 * Destroy the server resource for the given proxy.
	 *
	 * \param obj the proxy to destroy
	 *
	 * This requires X permissions on the core.
	 */
    destroy:       proc "c" (object: rawptr, proxy: rawptr) -> c.int,
}

node_events :: struct {
    version: u32,
    /**
	 * Notify node info
	 *
	 * \param info info about the node
	 */
    info:    proc(data: rawptr, info: ^node_info),
    /**
	 * Notify a node param
	 *
	 * Event emitted as a result of the enum_params method.
	 *
	 * \param seq the sequence number of the request
	 * \param id the param id
	 * \param index the param index
	 * \param next the param index of the next param
	 * \param param the parameter
	 */
    param:   proc(data: rawptr, seq: c.int, id: u32, idx: u32, next: u32, param: ^spa_pod),
}

node_state :: enum c.int {
    PW_NODE_STATE_ERROR     = -1, /**< error state */
    PW_NODE_STATE_CREATING  = 0, /**< the node is being created */
    PW_NODE_STATE_SUSPENDED = 1, /**< the node is suspended, the device might
					 *   be closed */
    PW_NODE_STATE_IDLE      = 2, /**< the node is running but there is no active
					 *   port */
    PW_NODE_STATE_RUNNING   = 3, /**< the node is running */
}

spa_param_info :: struct {
    id:      u32,
    flags:   u32,
    user:    u32,
    seq:     i32,
    padding: [4]u32,
}

node_info :: struct {
    id:               u32,
    max_input_ports:  u32,
    max_output_ports: u32,
    change_mask:      u64,
    n_input_ports:    u32,
    n_output_ports:   u32,
    state:            node_state,
    error:            cstring,
    props:            ^spa_dict,
    params:           ^spa_param_info,
    n_params:         u32,
}

node_methods :: struct {
    version:          u32,
    add_listener:     proc(
        object: rawptr,
        listener: ^spa_hook,
        events: ^node_events,
        data: rawptr,
    ) -> c.int,
    /**
	 * Subscribe to parameter changes
	 *
	 * Automatically emit param events for the given ids when
	 * they are changed.
	 *
	 * \param ids an array of param ids
	 * \param n_ids the number of ids in \a ids
	 *
	 * This requires X permissions on the node.
	 */
    subscribe_params: proc(object: rawptr, ids: ^u32, n_ids: u32) -> c.int,
    /**
	 * Enumerate node parameters
	 *
	 * Start enumeration of node parameters. For each param, a
	 * param event will be emitted.
	 *
	 * \param seq a sequence number to place in the reply
	 * \param id the parameter id to enum or PW_ID_ANY for all
	 * \param start the start index or 0 for the first param
	 * \param num the maximum number of params to retrieve
	 * \param filter a param filter or NULL
	 *
	 * This requires X permissions on the node.
	 */
    enum_params:      proc(
        object: rawptr,
        seq: c.int,
        id: u32,
        start: u32,
        num: u32,
        filter: ^spa_pod,
    ) -> c.int,
    /**
	 * Set a parameter on the node
	 *
	 * \param id the parameter id to set
	 * \param flags extra parameter flags
	 * \param param the parameter to set
	 *
	 * This requires X and W permissions on the node.
	 */
    set_param:        proc(object: rawptr, id: u32, flags: u32, param: ^spa_pod) -> c.int,
    /**
	 * Send a command to the node
	 *
	 * \param command the command to send
	 *
	 * This requires X and W permissions on the node.
	 */
    send_command:     proc(object: rawptr, command: ^spa_command) -> c.int,
}

core_info :: struct {
    id:          u32,
    cookie:      u32,
    user_name:   cstring,
    host_name:   cstring,
    version:     cstring,
    name:        cstring,
    change_mask: u64,
    props:       ^spa_dict,
}


link_events :: struct {
    version: u32,
    /**
	 * Notify link info
	 *
	 * \param info info about the link
	 */
    info:    proc(data: rawptr, info: ^link_info),
}

link_info :: struct {
    id:             u32, /**< id of the global */
    output_node_id: u32, /**< server side output node id */
    output_port_id: u32, /**< output port id */
    input_node_id:  u32, /**< server side input node id */
    input_port_id:  u32, /**< input port id */
    change_mask:    Link_Change_Mask_Set, /**< bitfield of changed fields since last call */
    state:          link_state, /**< the current state of the link */
    error:          cstring, /**< an error reason if \a state is error */
    format:         spa_pod, /**< format over link */
    props:          ^spa_dict, /**< the properties of the link */
}

Link_Change_Mask_Set :: bit_set[Link_Change_Mask]
Link_Change_Mask :: enum u64 {
    STATE  = 1 << 0,
    FORMAT = 1 << 1,
    PROPS  = 1 << 2,
    ALL    = (1 << 3) - 1,
}

link_state :: enum c.int {
    PW_LINK_STATE_ERROR       = -2, /**< the link is in error */
    PW_LINK_STATE_UNLINKED    = -1, /**< the link is unlinked */
    PW_LINK_STATE_INIT        = 0, /**< the link is initialized */
    PW_LINK_STATE_NEGOTIATING = 1, /**< the link is negotiating formats */
    PW_LINK_STATE_ALLOCATING  = 2, /**< the link is allocating buffers */
    PW_LINK_STATE_PAUSED      = 3, /**< the link is paused */
    PW_LINK_STATE_ACTIVE      = 4, /**< the link is active */
}

registry :: struct {}
client :: struct {}
node :: struct {}
main_loop :: struct {}
thread_loop :: struct {}
pw_context :: struct {}
impl_metadata :: struct {}
impl_module :: struct {}
stream :: struct {}
proxy :: struct {}
core :: struct {}
global :: struct {}
