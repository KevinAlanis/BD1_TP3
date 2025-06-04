package com.registro.usuarios.controlador.dto;

public class UsuarioRegistroDTO {

	private Long id;
	private String Username;
	private String password;

	public Long getId() {
		return id;
	}

	public void setId(Long id) {
		this.id = id;
	}

	public String getUsername() {
		return Username;
	}

	public void setUsername(String Username) {
		this.Username = Username;
	}

	public String getPassword() {
		return password;
	}

	public void setPassword(String password) {
		this.password = password;
	}


	public UsuarioRegistroDTO(String Username, String password) {
		super();
		this.Username = Username;
		this.password = password;
	}

	public UsuarioRegistroDTO() {

	}

}
