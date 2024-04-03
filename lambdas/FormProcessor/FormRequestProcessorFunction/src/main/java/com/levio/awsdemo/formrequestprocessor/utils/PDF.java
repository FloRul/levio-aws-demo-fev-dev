package com.levio.awsdemo.formrequestprocessor.utils;

import org.apache.pdfbox.cos.COSDocument;
import org.apache.pdfbox.io.RandomAccessRead;
import org.apache.pdfbox.pdfparser.PDFParser;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.text.PDFTextStripper;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;

public class PDF {

    public static String generateTextFromPDF(File file) throws IOException {
        String parsedText;
        PDFParser parser = new PDFParser((RandomAccessRead) new RandomAccessFile(file, "r"));
        parser.parse();

        COSDocument cosDoc = parser.parse().getDocument();
        PDFTextStripper pdfStripper = new PDFTextStripper();
        PDDocument pdDoc = new PDDocument(cosDoc);
        parsedText = pdfStripper.getText(pdDoc);

        return parsedText;
    }
}
