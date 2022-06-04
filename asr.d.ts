/**
 * Sets the tick rate of the runtime. This influences the amount of times the
 * `update` function is called per second.
 */
 declare function setTickRate(ticksPerSecond: number): void;
 /** Prints a log message for debugging purposes. */
 declare function printMessage(message: unknown): void;
 
 declare type Address = BigInt;
 
 declare class Process {
     /** Attaches to a process based on its name. */
     constructor(processName: string);
     /** Detaches from a process. */
     detach(): void;
     /**
      * Checks whether is a process is still open. You should detach from a
      * process and stop using it if this returns `false`.
      */
     isOpen(): boolean;
     /**
      * Reads memory from a process at the address given. A buffer with the
      * length specified will the returned.
      */
     read(address: Address, byteLength: number): ArrayBuffer;
     /** Gets the address of a module in a process. */
     getModuleAddress(name: string): Address | null;
 }
 
 declare enum TimerState {
     NotRunning = "NotRunning",
     Running = "Running",
     Paused = "Paused",
     Ended = "Ended",
 }
 
 declare namespace Timer {
     /** Gets the state that the timer currently is in. */
     function getState(): TimerState;
 
     /** Starts the timer. */
     function start(): void;
     /** Splits the current segment. */
     function split(): void;
     /** Resets the timer. */
     function reset(): void;
     /**
      * Sets a custom key value pair. This may be arbitrary information that the
      * auto splitter wants to provide for visualization.
      */
     function setVariable(key: unknown, value: unknown): void;
 
     /** Sets the game time. */
     function setGameTime(seconds: number): void;
     /**
      * Pauses the game time. This does not pause the timer, only the automatic
      * flow of time for the game time.
      */
     function pauseGameTime(): void;
     /**
      * Resumes the game time. This does not resume the timer, only the automatic
      * flow of time for the game time.
      */
     function resumeGameTime(): void;
 }
 
 declare class TextDecoder {
     /**
      * The TextDecoder() constructor returns a newly created TextDecoder object
      * for the encoding specified in parameter.
      *
      * If the value for utfLabel is unknown, or is one of the two values leading
      * to a 'replacement' decoding algorithm ( "iso-2022-cn" or
      * "iso-2022-cn-ext"), a RangeError is thrown.
      *
      * Note: Currently only UTF-8 is supported.
      */
     constructor();
     decode(buffer: ArrayBuffer | ArrayBufferView): string;
 }