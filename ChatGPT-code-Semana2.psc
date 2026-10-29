Algoritmo OrdenarTresNumeros
		Definir a, b, c Como Entero
		
		Escribir "Ingrese el primer numero:"
		Leer a
		Escribir "Ingrese el segundo numero:"
		Leer b
		Escribir "Ingrese el tercer numero:"
		Leer c
		
		Si a <= b Y a <= c Entonces
			Si b <= c Entonces
				Escribir a, ", ", b, ", ", c
			SiNo
				Escribir a, ", ", c, ", ", b
			FinSi
		SiNo
			Si b <= a Y b <= c Entonces
				Si a <= c Entonces
					Escribir b, ", ", a, ", ", c
				SiNo
					Escribir b, ", ", c, ", ", a
				FinSi
			SiNo
				Si a <= b Entonces
					Escribir c, ", ", a, ", ", b
				SiNo
					Escribir c, ", ", b, ", ", a
				FinSi
			FinSi
		FinSi
FinAlgoritmo


