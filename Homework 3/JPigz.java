// TA Starter Code to illustrate how to perform compression

import java.util.zip.*;
import java.io.*;
import java.nio.file.*;


class SingleThreadedGZipCompressor {
    public final static int BLOCK_SIZE = 131072;
    public final static int DICT_SIZE = 32768;
    private final static int GZIP_MAGIC = 0x8b1f;
    private final static int TRAILER_SIZE = 8;


    public ByteArrayOutputStream outStream;
    private CRC32 crc = new CRC32();

    
    public SingleThreadedGZipCompressor() {
	    this.outStream = new ByteArrayOutputStream();
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

    public void compress() throws FileNotFoundException, IOException {
	    this.writeHeader();
	    this.crc.reset();
	    
	    // Buffers for input blocks, compressed bocks, and dictionaries
	    byte[] blockBuf = new byte[BLOCK_SIZE];
	    byte[] nextBlockBuf = new byte[BLOCK_SIZE];
	    byte[] cmpBlockBuf = new byte[BLOCK_SIZE * 2];
	    byte[] dictBuf = new byte[DICT_SIZE];
	    
	    Deflater compressor = new Deflater(Deflater.DEFAULT_COMPRESSION, true);

	    long totalBytesRead = 0;
	    boolean hasDict = false;
	    
	    int nBytes = System.in.read(blockBuf);
	    int nextNBytes = System.in.read(nextBlockBuf);
	    totalBytesRead += nBytes;
	    
	    while (nBytes > 0) {
		    // Update the CRC every time we read in a new block.
		    crc.update(blockBuf, 0, nBytes);
		    System.err.println(crc.getValue());

		    compressor.reset();
		    
		    // If we saved a dictionary from the last block, prime the deflater with it 
		    if (hasDict) {
			    compressor.setDictionary(dictBuf);
		    }
		    
		    compressor.setInput(blockBuf, 0, nBytes);
		    
		    if (nextNBytes < 0) {
			    // If we've read all the bytes in the file, this is the last block.
			    // We have to clean out the deflater properly 
			    if (!compressor.finished()) {
				    compressor.finish();
				    while (!compressor.finished()) {
					    int deflatedBytes = compressor.deflate(cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.NO_FLUSH);
					    if (deflatedBytes > 0) {
						    outStream.write(cmpBlockBuf, 0, deflatedBytes);
					    }
				    }
			    }
		    } else {
			    // Otherwise, just deflate and then write the compressed block out. Not using SYNC_FLUSH here leads to
			    // some issues, but using it probably results in less efficient compression. There's probably a better
			    // way to deal with this.
			    int deflatedBytes = compressor.deflate(cmpBlockBuf, 0, cmpBlockBuf.length, Deflater.SYNC_FLUSH);
			    if (deflatedBytes > 0) {
				    outStream.write(cmpBlockBuf, 0, deflatedBytes);
			    }
		    }
		    
		    // If we read in enough bytes in this block, store the last part as the dictionary for the next iteration
		    if (nBytes >= DICT_SIZE) {
			    System.arraycopy(blockBuf, nBytes - DICT_SIZE, dictBuf, 0, DICT_SIZE);
			    hasDict = true;
		    } else {
			    hasDict = false;
		    }
		    
		    nBytes = nextNBytes;
		    blockBuf = nextBlockBuf.clone();
		    nextNBytes = System.in.read(nextBlockBuf);
		    totalBytesRead += nBytes;
	    }
	    totalBytesRead++;


	    // Finally, write the trailer and then write to STDOUT 
	    byte[] trailerBuf = new byte[TRAILER_SIZE];
	    writeTrailer(totalBytesRead, trailerBuf, 0);
	    outStream.write(trailerBuf);
	    outStream.writeTo(System.out);
    }
}


public class JPigz {
    public static void main (String[] args) throws FileNotFoundException, IOException {
	    SingleThreadedGZipCompressor cmp = new SingleThreadedGZipCompressor();
	    cmp.compress();
    }
}
