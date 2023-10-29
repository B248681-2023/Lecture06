#!/bin/bash

> remote_blast_accession_numbers.txt
> remote_blast_sequences.txt


OLD_IFS=$IFS
IFS=":"

cat remote_blast.txt | awk 'BEGIN {FS="\t"} {
	if(NR > 24){
		if(NR ==25){
			new_sequence="no"
			sequence_text=""
			accessions_done="no";
		}
		if($1 ~ /^>/) accessions_done = "yes";
		if(accessions_done == "no" && $0 != "") {
			split($0, split_array, " ");
			print "accession:"split_array[1];
		}
		if($1 ~ /^>/) {
			if(accessions_done=="yes") print sequence_text;
			accessions_done="yes";
			new_sequence="yes";
			sequence_text=""
		}
		if(new_sequence == "yes") {
			sequence_text= sequence_text"\n"$0;
		}
	}
}' | while read dis_part dat_part ; do
	if [[ "$dis_part" == "accession" ]]; then 
		echo "$dat_part" >> remote_blast_accession_numbers.txt;
	else 
		echo "$dis_part" >> remote_blast_sequences.txt;
	fi
done
IFS=$'\t';
key_attributes="";
echo -e "Accession\tLength\tIdentities\tNum Mismatches\tPercentage of length that is mismatches." > key_attributes.txt;
cat remote_blast_sequences.txt | awk 'BEGIN {FS=" "} {
	if(NR == 1) {
		sequence_id = "";
		sequence_length = "";
		sequence_percent_id = "";
		number_of_mismatches = "";
	}
	if($1 ~ /^>/) sequence_id=substr($1,2);
	if($1 ~ /^Length/) {
		isolated_length=$1;
		sub("Length=","",isolated_length);
		sequence_length=isolated_length;
	}
	if($1 == "Identities") {
		sequence_percent_id=$3;
	}
	if (sequence_id != "" && sequence_length != "" && sequence_percent_id != "") {
		split($3, percent_array, "/");
		number_of_mismatches=percent_array[2]-percent_array[1];
		percentage_is_mismatch=(number_of_mismatches/sequence_length)*100;
		print sequence_id "\t" sequence_length "\t" sequence_percent_id "\t" number_of_mismatches "\t" percentage_is_mismatch;
		sequence_id="";
		sequence_length="";
		sequence_percent_id="";
		number_of_mismatches="";
}
}'| while read attribute; do
		echo "$attribute" >> key_attributes.txt;
done

> mismatches.txt
awk 'BEGIN {FS="\t"} {
	if(NR==1) {
		less_20="";
		more_20="";
		more_20_shorter_100=""
		shorter_100="";
	}
	if(NR>1) {
		if($4<20) less_20=less_20"\n"$1;
		if($4>20) {
			if($2<100) more_20_shorter_100=more_20_shorter_100"\n"$1;
			else more_20=more_20"\n"$1;
			}
		if($2<100) shorter_100=shorter_100"\n"$1;
		}
}

END {
	print "Sequences that have fewer than 20 mismatches:\n" less_20 "\nSequences that have greater than 20 mismatches:\n"more_20"\nSequences whose length are shorter than 100 and have more than 20 mismatches:\n"more_20_shorter_100"\nSequences that are shorter than 100.\n"shorter_100;
}' key_attributes.txt > key_measures.txt


sort -t $'\t' -k4,4 key_attributes.txt > sorted_mismatches.txt;
sort -t $'\t' -k3,3 key_attributes.txt > sorted_identities.txt;
IFS=$OLD_IFS
