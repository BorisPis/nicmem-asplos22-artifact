all:
	./post.py memcpy.csv memcpy_memic.csv > result.csv
	./post.py memcpy_reverse.csv memcpy_memic_reverse.csv > result_reverse.csv
	gnuplot memcpy.gp
	gnuplot memcpy_reverse.gp

clean:
	rm -f *.eps

