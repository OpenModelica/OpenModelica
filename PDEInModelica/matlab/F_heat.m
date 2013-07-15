function ret = F_heat(~, u_t, ~, u_xx, ~, ~)
	alpha = 1;
	ret = u_t - alpha*u_xx;
end