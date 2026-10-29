Algoritmo OrdenarTres
	//me toco con pseint ya que mi compu no dejo python, mañana miro eso con mas tiempo del porque no se pudo
	// Pide tres números enteros y los muestra de menorrr a mayorrr
	// SoloSi ... Entoncess ... SiNo y comparacines
	Definir a, b, c Como Entero
	
	Escribir "Primer número:"
	Leer a
	Escribir "Segundo número:"
	Leer b
	Escribir "Tercer número:"
	Leer c
	
	Si a <= b Entonces
		// a va antes que b
		Si b <= c Entonces
			Escribir a, " ", b, " ", c
		SiNo
			// c es menor que b: falta ubicar c frente a a 
			Si a <= c Entonces
				Escribir a, " ", c, " ", b
			SiNo
				Escribir c, " ", a, " ", b
			FinSi
		FinSi
	SiNo
		// b va antes que a
		Si a <= c Entonces
			Escribir b, " ", a, " ", c
		SiNo
			// c es menor que a: falta ubicar c frente a b
			Si b <= c Entonces
				Escribir b, " ", c, " ", a
			SiNo
				Escribir c, " ", b, " ", a
			FinSi
		FinSi
	FinSi
FinAlgoritmo
