import java.io.*;
import java.nio.file.*;
import java.util.concurrent.*;
import java.util.*;
import java.util.zip.*;


class MultiThreadedGZipCompressor {
    public final static int BLOCK_SIZE = 131072;  // 128 KiB
    public final static int DICT_SIZE = 32768;    // 32 KiB
    private final static int GZIP_MAGIC = 0x8b1f;
    private final static int TRAILER_SIZE = 8;

    private CRC32 crc = new CRC32();
    private volatile List<LinkedBlockingQueue<byte[]>> blockQ;
    private volatile List<LinkedBlockingQueue<Integer>> nBytesQ;
    private volatile List<LinkedBlockingQueue<byte[]>> dictQ;
    private int processes;
    private int outputNum = 1;
    private int lastBlockNum = -1;
    private boolean lastBlock = false;

    public ByteArrayOutputStream outStream;


    private class WorkerThread implements Runnable {
	    private int blockNum;
	    private LinkedBlockingQueue<byte[]> personalQ;
	    private LinkedBlockingQueue<Integer> personalnBytesQ;
	    private LinkedBlockingQueue<byte[]> personalDictQ;
	    private ByteArrayOutputStream out;
	    private Deflater compressor;

	    public WorkerThread(int blockNum, int thNum) {
		    this.blockNum = blockNum;
		    this.personalQ = blockQ.get(thNum);
		    this.personalnBytesQ = nBytesQ.get(thNum);
		    this.personalDictQ = dictQ.get(thNum);
		    this.out = new ByteArrayOutputStream();
		    this.compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true);
	    }


	    // Output compressed data to stdout
	    public void output(byte[] cmpData, int nBytes) throws InterruptedException, IOException {

		    // Wait for turn to output by spinning with slightly less spinning
		    synchronized(this) {
			    while(this.blockNum != outputNum) { wait(100); }
		    }
		    
		    byte[] cmpBlockBuf = new byte[BLOCK_SIZE * 2];
		    
		    if (blockNum == lastBlockNum) {
			    // If this is the last block, we need to clean out the deflater properly 		    
			    if (!this.compressor.finished()) {
				    this.compressor.finish();
				    while (!this.compressor.finished()) {
					    int deflatedBytes = this.compressor.deflate(cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.NO_FLUSH);
					    if (deflatedBytes > 0) {
						    this.out.write(cmpBlockBuf, 0, deflatedBytes);
					    }
				    }
			    }
		    } else {
			    // Otherwise, just deflate and then write the compressed block out. Not using SYNC_FLUSH here leads to
			    // some issues, but using it probably results in less efficient compression. There's probably a better
			    // way to deal with this.
			    int deflatedBytes = this.compressor.deflate(cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.SYNC_FLUSH);
			    if (deflatedBytes > 0) {
				    this.out.write(cmpBlockBuf, 0, deflatedBytes);
			    }
		    }

		    this.blockNum += processes;
		    this.out.writeTo(System.out);
		    this.out.reset();
		    incrementOutput();
	    }


	    // Compress a single block
	    public void run() {
		    // Process all the blocks in its personal queue
		    while (!(Arrays.equals(personalQ.peek(), "end".getBytes()))) {
			    
			    // buffers for uncompressed data and compressed data
			    byte[] data = new byte[BLOCK_SIZE];
			    byte[] dict = new byte[DICT_SIZE];
			    int nBytes = 0;

			    // Retrieve a block
			    try { 
				    data = this.personalQ.take(); 
				    nBytes = this.personalnBytesQ.take();
				    dict = this.personalDictQ.poll();
			    }
			    catch (InterruptedException e) { printError("Error with thread " + Thread.currentThread().getName() + " retrieving a block"); }

			    // Reset the compressor every time we read in a new block
			    this.compressor.reset();
			    
			    // If we saved a dictionary from the last block, prime the deflater with it
			    if (dict != null) {
				    compressor.setDictionary(dict);
			    }

			    this.compressor.setInput(data, 0, nBytes);

			    // Output the compressed data
			    try { output(data, nBytes); }
			    catch (InterruptedException|IOException e) { printError("Error with outputting the compressed data"); }
		    }
	    }
    }

    
    public MultiThreadedGZipCompressor(int processes) {
	    this.outStream = new ByteArrayOutputStream();
	    this.processes = processes;
	    this.blockQ = new ArrayList<LinkedBlockingQueue<byte[]>>(processes);
	    this.nBytesQ = new ArrayList<LinkedBlockingQueue<Integer>>(processes);
	    this.dictQ = new ArrayList<LinkedBlockingQueue<byte[]>>(processes);
	    for (int i = 0; i < processes; i++) {
		    blockQ.add(i, new LinkedBlockingQueue<byte[]>());
		    nBytesQ.add(i, new LinkedBlockingQueue<Integer>()); 
		    dictQ.add(i, new LinkedBlockingQueue<byte[]>());
	    }
    }

    
    private synchronized void incrementOutput() {
	    this.outputNum++;
    }


    public void printError(String msg) {
	    System.err.println(msg);
	    System.exit(1);
    }


    private void writeHeader() throws IOException {
        outStream.write(new byte[] {
                      (byte) GZIP_MAGIC,        // Magic number (short)
                      (byte)(GZIP_MAGIC >> 8),  // Magic number (short)
                      Deflater.DEFLATED,        // Compression method (CM)
                      0,                        // Flags (FLG)
                      0,                        // Modification time MTIME (int)
                      0,                        // Modification time MTIME (int)
                      0,                        // Modification time MTIME (int)
                      0,                        // Modification time MTIME (int)Sfil
                      0,                        // Extra flags (XFLG)
                      0                         // Operating system (OS)
                  });
	outStream.writeTo(System.out);
	outStream.reset();
    }


    /*
     * Writes GZIP member trailer to a byte array, starting at a given
     * offset.
     */
    private void writeTrailer(long totalBytes, byte[] buf, int offset) throws IOException {
        writeInt((int)crc.getValue(), buf, offset); // CRC-32 of uncompr. data
        writeInt((int)totalBytes, buf, offset + 4); // Number of uncompr. bytes
    }

    /*
     * Writes integer in Intel byte order to a byte array, starting at a
     * given offset.
     */
    private void writeInt(int i, byte[] buf, int offset) throws IOException {
        writeShort(i & 0xffff, buf, offset);
        writeShort((i >> 16) & 0xffff, buf, offset + 2);
    }

    /*
     * Writes short integer in Intel byte order to a byte array, starting
     * at a given offset
     */
    private void writeShort(int s, byte[] buf, int offset) throws IOException {
        buf[offset] = (byte)(s & 0xff);
        buf[offset + 1] = (byte)((s >> 8) & 0xff);
    }


    /* 
     * Compresses the data 
     */
    public void compress() throws IOException, InterruptedException {
	    this.writeHeader();
	    this.crc.reset();
	    
	    // Buffers for input blocks and dictionaries
	    byte[] blockBuf = new byte[BLOCK_SIZE];
	    byte[] nextBlockBuf = new byte[BLOCK_SIZE];
	    
	    long totalBytesRead = 0;  
	    
	    // Read in first block
	    int nBytes = System.in.read(blockBuf);
	    int nextNBytes = System.in.read(nextBlockBuf);
	    int blocksRead = 0;
	    totalBytesRead += nBytes;    

	    // Initialize -p # of threads and give them a starting block number and their thread number
	    ExecutorService exec = Executors.newFixedThreadPool(this.processes);
	    for (int i = 1; i <= this.processes; i++) {
		    exec.execute(new WorkerThread(i, i - 1));
	    }
	    
	    // Read from STDIN while there is input and give blocks to threads
	    while (nBytes > 0) {
		    // Check if we are currently on the last block
		    if (nextNBytes < 0) {
			    lastBlockNum = blocksRead + 1;
			    lastBlock = true;
		    }

		    // Update the CRC every time we read in a new block
		    crc.update(blockBuf, 0, nBytes);
		    
		    // Make a new byte array to add to a thread's queue, put it into the right queue, add to dictionary
		    byte[] qBuf = blockBuf.clone();
		    int indice = blocksRead % processes;
		    blockQ.get(indice).put(qBuf);
		    nBytesQ.get(indice).put(nBytes);
		    blocksRead++;

		    // If we read in enough bytes in this block, store the last part as the dictionary for the next iteration
		    byte[] dictBuf = new byte[DICT_SIZE];
                    if (nBytes >= DICT_SIZE) {
                            System.err.println("hasDict = true " + nBytes);
                            System.arraycopy(blockBuf, nBytes - DICT_SIZE, dictBuf, 0, DICT_SIZE);
			    dictQ.get(blocksRead % processes).put(dictBuf);
                    }
		    		    
		    // Read in the next block from STDOUT 
		    nBytes = nextNBytes;
		    blockBuf = nextBlockBuf.clone();
		    nextNBytes = System.in.read(nextBlockBuf);
		    totalBytesRead += nBytes;
	    }
	    totalBytesRead++; // Add 1 to account for the -1 returned by the last read() EOF signal

	    // Add "end" to each queue to signal that there are no more blocks
	    for (int i = 0; i < processes; i++) {
		    blockQ.get(i).add("end".getBytes());
	    }

	    // Shut down the Executor
	    exec.shutdown();

	    // Wait for 1 minute for threads to terminate
	    if (exec.awaitTermination(60, TimeUnit.SECONDS)) {
		    // Finally, write the trailer and then write to STDOUT 
		    byte[] trailerBuf = new byte[TRAILER_SIZE];
		    writeTrailer(totalBytesRead, trailerBuf, 0);
		    outStream.write(trailerBuf);
		    outStream.writeTo(System.out);
	    }
    }
}


public class Pigzj {
    public static void printError(String msg) {
	    System.err.println(msg);
	    System.exit(1);
    }


    public static void main (String[] args) throws FileNotFoundException, IOException, InterruptedException {
	    int processes = 0;

	    // Parse command line arguments
	    if (args.length == 2 && args[0].equals("-p")) {
		    try {
			    processes = Integer.parseInt(args[1]);
			    if (processes > Runtime.getRuntime().availableProcessors()) {
				    printError("Error: the number of processes requested is too high"); 
			    }
			    else if (processes < 0) {
				    printError("Error: a positive integer must be inputted");
			    }
		    } catch (NumberFormatException e) {
			    printError("Error: a positive integer must be inputted");
		    }
	    }
	    else if (args.length == 0) {
		    processes = 1; // Runtime.getRuntime().availableProcessors();
	    }
	    else {
		    printError("Usage: java <execName> [-p processes]");
	    }
	    
	    MultiThreadedGZipCompressor cmp = new MultiThreadedGZipCompressor(processes);
	    cmp.compress();
    }
}
